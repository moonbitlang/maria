///|
priv suberror HttpError {
  HttpError(code~ : Int, body~ : String)
} derive(Show, ToJson)

///|
/// Execute a chat completion request with the OpenAI API.
///
/// Sends a chat completion request to the model's endpoint and returns the parsed response.
/// Includes automatic retry logic with exponential backoff for transient failures.
///
/// Parameters:
/// - model: The model configuration containing API credentials and endpoint
/// - request: The chat completion parameters including messages, tools, and settings
///
/// Returns a ChatCompletion object containing the model's response, including generated
/// messages, token usage, and metadata.
///
/// Raises HttpError if the API returns a non-2xx status code.
pub async fn chat(
  model~ : @model.Model,
  request : Request,
  logger? : @pino.Logger = @pino.logger("openai", @pino.Transport::sink()),
  extra_body? : Map[String, Json] = {},
) -> ChatCompletion {
  // Dispatch based on model type
  match model.model_type {
    SaaS(CodexOAuth) => chat_codex(model~, request, logger~)
    _ => chat_openai(model~, request, logger~, extra_body~)
  }
}

///|
/// Execute a chat completion request using the standard OpenAI API.
async fn chat_openai(
  model~ : @model.Model,
  request : Request,
  logger~ : @pino.Logger,
  extra_body~ : Map[String, Json],
) -> ChatCompletion {
  @async.retry(
    ExponentialDelay(initial=1000, factor=2.0, maximum=16000),
    max_retry=5,
    fatal_error=error => match error {
      HttpError(code=403, ..) => true
      _ => false
    },
    () => {
      logger.debug("RequestSent", data={
        "model": { "name": model.model_name, "base_url": model.base_url },
        "request": request,
      })
      let url = "\{model.base_url}/chat/completions"
      let uri = Uri::parse(url)
      let client = @http.Client::new("\{uri.schema}://\{uri.host}", headers={
        "Authorization": "Bearer \{model.api_key}",
        "Content-Type": "application/json",
        "Connection": "close",
      })
      defer client.close()
      let body = request.to_json()
      guard body is Object(body) else {
        abort("Request body is not a JSON object")
      }
      for k, v in extra_body {
        body[k] = v
      }
      let response = client.post(uri.path, Json::object(body))
      guard response.code is (200..=299) else {
        raise HttpError(code=response.code, body=client.read_all().text())
      }
      if request.stream is Some(true) {
        let reader = ChunkReader::new(client)
        let builder = ChatCompletionBuilder::new()
        while reader.read() is Some(chunk) {
          logger.debug("ChunkReceived", data={ "chunk": chunk })
          builder.add_chunk(chunk)
        }
        let chat_completion = builder.to_chat_completion()
        logger.debug("ResponseReceived", data={
          "model": { "name": model.model_name, "base_url": model.base_url },
          "response_code": response.code,
          "response_body": chat_completion,
        })
        chat_completion
      } else {
        let body = client.read_all().text()
        let json = @json.parse(body)
        let chat_completion : ChatCompletion = @json.from_json(json)
        logger.debug("ResponseReceived", data={
          "model": { "name": model.model_name, "base_url": model.base_url },
          "response_code": response.code,
          "response_body": chat_completion,
        })
        chat_completion
      }
    },
  )
}

///|
/// Execute a chat completion request using the Codex OAuth API (ChatGPT backend).
/// Converts Chat Completions format to Responses API format and back.
/// Automatically refreshes tokens on 401 errors.
async fn chat_codex(
  model~ : @model.Model,
  request : Request,
  logger~ : @pino.Logger,
) -> ChatCompletion {
  // Get initial credentials from model or load from file
  let (access_token, account_id) = match
    (model.access_token, model.account_id) {
    (Some(at), Some(aid)) => (at, aid)
    _ =>
      // Try to load credentials from file
      try {
        let creds = @oauth.load_credentials()
        (creds.accessToken, creds.accountId)
      } catch {
        _ =>
          raise HttpError(
            code=401,
            body="Missing access_token/account_id for CodexOAuth model and no saved credentials found",
          )
      }
  }
  // Track if we've already tried refreshing
  let has_refreshed = Ref::new(false)
  let current_access_token = Ref::new(access_token)
  let current_account_id = Ref::new(account_id)
  @async.retry(
    ExponentialDelay(initial=1000, factor=2.0, maximum=16000),
    max_retry=5,
    fatal_error=error => match error {
      HttpError(code=403, ..) => true
      _ => false
    },
    () => {
      logger.debug("CodexRequestSent", data={
        "model": { "name": model.model_name, "base_url": model.base_url },
        "request": request,
      })
      // Convert Chat Completion messages to Responses API input format
      let input = convert_messages_to_input(request.messages)
      let instructions = @oauth.base_instructions
      // Build Responses API request
      let codex_request = @oauth.ResponsesRequest::new(
        model=model.model_name,
        input~,
        instructions~,
        stream=true,
        store=false,
      )
      // Execute the request
      let chunks : Array[String] = []
      let error_ref : Ref[Error?] = Ref::new(None)
      let done = Ref::new(false)
      do_codex_stream_request(
        current_access_token.val,
        current_account_id.val,
        codex_request,
        on_chunk=fn(chunk) { chunks.push(chunk) },
        on_complete=fn() { done.val = true },
        on_error=fn(err) { error_ref.val = Some(err) },
      )
      // Check for 401 error and try to refresh token
      match error_ref.val {
        Some(HttpError(code=401, ..)) if not(has_refreshed.val) => {
          logger.info("Received 401, attempting to refresh token")
          try {
            let refreshed = @oauth.refresh_and_save_credentials()
            current_access_token.val = refreshed.accessToken
            current_account_id.val = refreshed.accountId
            has_refreshed.val = true
            logger.info("Token refreshed successfully, retrying request")
            // Re-raise to trigger retry
            raise error_ref.val.unwrap()
          } catch {
            refresh_err => {
              logger.error("Failed to refresh token", data={
                "error": refresh_err.to_string(),
              })
              raise error_ref.val.unwrap()
            }
          }
        }
        Some(err) => raise err
        None => ()
      }
      // Convert response to ChatCompletion format
      let full_text = chunks.iter().fold(init="", fn(acc, c) { acc + c })
      let chat_completion = codex_response_to_chat_completion(
        model.model_name,
        full_text,
      )
      logger.debug("CodexResponseReceived", data={
        "model": { "name": model.model_name, "base_url": model.base_url },
        "response": chat_completion,
      })
      chat_completion
    },
  )
}

///|
/// Execute a streaming request to Codex API.
async fn do_codex_stream_request(
  access_token : String,
  account_id : String,
  request : @oauth.ResponsesRequest,
  on_chunk~ : (String) -> Unit,
  on_complete~ : () -> Unit,
  on_error~ : (Error) -> Unit,
) -> Unit {
  try {
    let client = @http.Client::new("https://chatgpt.com", headers={
      "Authorization": "Bearer \{access_token}",
      "ChatGPT-Account-ID": account_id,
      "Content-Type": "application/json",
      "Accept": "text/event-stream",
      "originator": "codex_cli_rs",
      "User-Agent": "codex_cli_rs/1.0.0",
    })
    defer client.close()
    let body = request.to_json()
    guard body is Object(body_obj) else {
      on_error(HttpError(code=500, body="Invalid request body"))
      return
    }
    body_obj["stream"] = true
    let response = client.post(
      "/backend-api/codex/responses",
      Json::object(body_obj),
    )
    guard response.code is (200..=299) else {
      let error_text = client.read_all().text()
      on_error(
        HttpError(code=response.code, body="API request failed: \{error_text}"),
      )
      return
    }
    let reader = CodexChunkReader::new(client)
    while reader.read() is Some(chunk) {
      on_chunk(chunk)
    }
    on_complete()
  } catch {
    error => on_error(error)
  }
}

///|
priv struct CodexChunkReader(&@io.Reader)

///|
fn CodexChunkReader::new(reader : &@io.Reader) -> CodexChunkReader {
  CodexChunkReader(reader)
}

///|
async fn CodexChunkReader::read(self : CodexChunkReader) -> String? {
  for {
    guard self.0.read_until("\n") is Some(line) else { return None }
    guard line is [.. "data: ", .. rest] else { continue }
    let data = rest.trim().to_string()
    if data == "[DONE]" {
      return None
    }
    try {
      let json = @json.parse(data)
      guard json is Object(obj) else { continue }
      if obj.get("type") is Some(String("response.output_text.delta")) {
        if obj.get("delta") is Some(String(delta)) {
          return Some(delta)
        }
      }
      if obj.get("type") is Some(String("response.content_part.delta")) {
        if obj.get("delta") is Some(Object(delta_obj)) {
          if delta_obj.get("text") is Some(String(text)) {
            return Some(text)
          }
        }
      }
      continue
    } catch {
      _ => continue
    }
  }
}

///|
/// Extract text content from content parts array.
fn extract_text_content(
  parts : Array[ChatCompletionContentPartParam],
) -> String {
  let texts : Array[String] = []
  for part in parts {
    match part {
      Text(text_part) => texts.push(text_part.text)
    }
  }
  texts
  .iter()
  .fold(init="", fn(acc, t) { if acc.is_empty() { t } else { acc + "\n" + t } })
}

///|
/// Convert Chat Completion messages to Responses API input format.
fn convert_messages_to_input(
  messages : Array[ChatCompletionMessageParam],
) -> Array[@oauth.InputItem] {
  let result : Array[@oauth.InputItem] = []
  for msg in messages {
    match msg {
      System(_) => continue // Skip system messages (they become instructions)
      User(user_msg) => {
        let text = extract_text_content(user_msg.content)
        result.push(
          @oauth.InputItem::new(type_="message", role=@oauth.User, content=[
            @oauth.ContentPart::new(type_=@oauth.InputText, text~),
          ]),
        )
      }
      Assistant(assistant_msg) => {
        let text = extract_text_content(assistant_msg.content)
        result.push(
          @oauth.InputItem::new(type_="message", role=@oauth.Assistant, content=[
            @oauth.ContentPart::new(type_=@oauth.OutputText, text~),
          ]),
        )
      }
      Tool(tool_msg) => {
        // Convert tool message to user message with tool output
        let text = extract_text_content(tool_msg.content)
        result.push(
          @oauth.InputItem::new(type_="message", role=@oauth.User, content=[
            @oauth.ContentPart::new(type_=@oauth.InputText, text~),
          ]),
        )
      }
    }
  }
  result
}

///|
/// Convert Codex response text to ChatCompletion format.
fn codex_response_to_chat_completion(
  model_name : String,
  content : String,
) -> ChatCompletion {
  ChatCompletion::new(
    id="codex-response",
    choices=[
      ChatCompletionChoice::new(
        index=0,
        message=ChatCompletionMessage::new(content~),
        finish_reason=Stop,
      ),
    ],
    created=0,
    model=model_name,
  )
}

///|
priv struct ChunkReader(&@io.Reader)

///|
fn ChunkReader::new(reader : &@io.Reader) -> ChunkReader {
  ChunkReader(reader)
}

///|
async fn ChunkReader::read(self : ChunkReader) -> ChatCompletionChunk? {
  for {
    guard self.0.read_until("\n") is Some(line) else { return None }
    guard line is [.. "data: ", .. rest] else { continue }
    if rest.trim() == "[DONE]" {
      return None
    }
    let json = @json.parse(rest)
    let chunk : ChatCompletionChunk = @json.from_json(json)
    return Some(chunk)
  }
}

///|
/// Generate a simple text response from a prompt.
///
/// Convenience function that sends a single user prompt to the model and returns
/// the text content of the response. Automatically handles the system message and
/// extraction of the response content.
///
/// Parameters:
/// - model: The model configuration containing API credentials and endpoint
/// - prompt: The user's prompt text
///
/// Returns the text content of the model's response.
/// Fails if the completion has no content in the message.
pub async fn text(model~ : @model.Model, prompt~ : String) -> String {
  let completion = chat(
    model~,
    chat_completion(
      model=model.model_name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content=prompt),
      ],
      max_tokens=150,
      temperature=0.7,
    ),
  )
  guard completion.choices[0].message.content is Some(content) else {
    fail("No content in completion message")
  }
  content
}

///|
fn extract_first_json_block(content : String) -> String? {
  content
  .split("```json")
  .drop(1)
  .take(1)
  .peek()
  .bind(block => block
    .split("```")
    .take(1)
    .peek()
    .map(s => s.trim(char_set=" \r\n\t").to_string()))
}

///|
test "extract_first_json_block" {
  let content =
    #|Here is some text.
    #|```json
    #|{
    #|  "key": "value"
    #|}
    #|```
    #|Some more text.
    #|```json
    #|{
    #|  "another_key": "another_value"
    #|}
    #|```
  @json.inspect(extract_first_json_block(content), content=[
    "{\n  \"key\": \"value\"\n}",
  ])
}

///|
/// Generate a JSON response from a prompt.
///
/// Requests the model to return a JSON object in a code block (wrapped in ```json```)
/// and extracts the first JSON block from the response.
///
/// Parameters:
/// - model: The model configuration containing API credentials and endpoint
/// - prompt: The user's prompt text requesting JSON output
///
/// Returns a parsed Json object from the model's response.
///
/// Fails if the completion has no content, no JSON code block is found in the response,
/// or the JSON cannot be parsed.
pub async fn json(model~ : @model.Model, prompt~ : String) -> Json {
  let completion = chat(
    model~,
    chat_completion(
      model=model.model_name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content=prompt),
      ],
      max_tokens=150,
      temperature=0.7,
    ),
  )
  guard completion.choices[0].message.content is Some(content) else {
    fail("No content in completion message")
  }
  guard extract_first_json_block(content) is Some(content) else {
    fail("No JSON block found in completion message")
  }
  content |> @json.parse()
}

///|
/// Trait for types that can be automatically generated from structured prompts.
///
/// Types implementing this trait can describe themselves with a name, description,
/// and JSON schema, allowing the model to generate responses that conform to
/// the expected structure.
pub(open) trait Structural: @json.FromJson {
  name() -> String
  description() -> String
  schema() -> @schema.Schema
}

///|
/// Generate structured data from a prompt using JSON schema.
///
/// This function uses the model's JSON schema support to ensure the response
/// conforms to a specific structure defined by the type parameter `T`. The
/// response is automatically parsed and validated against the schema.
///
/// # Type Parameters
/// - `T`: A type implementing `Structural` trait that defines the expected schema
///
/// # Parameters
/// - `model`: The model configuration containing API credentials and endpoint
/// - `prompt`: The user's prompt text
///
/// # Returns
/// A value of type `T` parsed from the model's structured response
///
/// Fails if the completion has no content, the JSON cannot be parsed,
/// or the parsed JSON doesn't match the expected schema.
pub async fn[T : Structural] data(model~ : @model.Model, prompt~ : String) -> T {
  let completion = chat(
    model~,
    chat_completion(
      model=model.model_name,
      messages=[
        system_message(content="You are a helpful assistant."),
        user_message(content=prompt),
      ],
      max_tokens=150,
      temperature=0.7,
      response_format=json_schema(
        name=T::name(),
        schema=T::schema().to_json(),
        description=T::description(),
      ),
    ),
  )
  guard completion.choices[0].message.content is Some(content) else {
    fail("No content in completion message")
  }
  content |> @json.parse() |> @json.from_json()
}
