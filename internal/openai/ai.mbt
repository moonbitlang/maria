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
    SaaS(Copilot) => chat_copilot(model~, request, logger~)
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
async fn chat_codex(
  model~ : @model.Model,
  request : Request,
  logger~ : @pino.Logger,
) -> ChatCompletion {
  let (access_token, account_id) = match
    (model.access_token, model.account_id) {
    (Some(at), Some(aid)) => (at, aid)
    _ =>
      try {
        let creds = @codex.load_credentials()
        (creds.accessToken, creds.accountId)
      } catch {
        _ =>
          raise HttpError(
            code=401,
            body="Missing access_token/account_id for CodexOAuth model and no saved credentials found",
          )
      }
  }
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
      let input = convert_messages_to_input(request.messages)
      let instructions = @codex.base_instructions
      let tools = convert_tools_to_responses_api(request.tools)
      let codex_request = @responses.ResponsesRequest::new(
        model=model.model_name,
        input~,
        instructions~,
        tools~,
        stream=true,
        store=false,
      )
      let result = do_codex_stream_request(
        current_access_token.val,
        current_account_id.val,
        codex_request,
      ) catch {
        HttpError(code=401, ..) as err if not(has_refreshed.val) => {
          logger.info("Received 401, attempting to refresh token")
          has_refreshed.val = true // Mark as refreshed to prevent infinite loop
          // Try refresh first, then re-login if refresh fails
          let refresh_result : @codex.Credentials? = Some(
            @codex.refresh_and_save_credentials(),
          ) catch {
            _ => None
          }
          match refresh_result {
            Some(refreshed) => {
              current_access_token.val = refreshed.accessToken
              current_account_id.val = refreshed.accountId
              logger.info("Token refreshed successfully, retrying request")
            }
            None => {
              logger.info("Refresh failed, triggering re-login flow")
              let new_creds = @codex.start_oauth_flow() catch {
                login_err => {
                  logger.error("Re-login failed", data={
                    "error": login_err.to_string(),
                  })
                  raise HttpError(
                    code=401,
                    body="Re-login failed: \{login_err}",
                  )
                }
              }
              current_access_token.val = new_creds.accessToken
              current_account_id.val = new_creds.accountId
              logger.info("Re-login successful, retrying request")
            }
          }
          raise err
        }
        err => raise err
      }
      let chat_completion = codex_stream_result_to_chat_completion(
        model.model_name,
        result,
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
/// Execute a chat completion request using GitHub Copilot API.
async fn chat_copilot(
  model~ : @model.Model,
  request : Request,
  logger~ : @pino.Logger,
) -> ChatCompletion {
  // Get valid credentials (auto-refresh if needed)
  let credentials = @copilot.get_valid_credentials() catch {
    err =>
      raise HttpError(
        code=401,
        body="Failed to get Copilot credentials: \{err}",
      )
  }
  let has_refreshed = Ref::new(false)
  let current_token = Ref::new(credentials.copilot_token)
  @async.retry(
    ExponentialDelay(initial=1000, factor=2.0, maximum=16000),
    max_retry=5,
    fatal_error=error => match error {
      HttpError(code=403, ..) => true
      _ => false
    },
    () => {
      logger.debug("CopilotRequestSent", data={
        "model": { "name": model.model_name, "base_url": model.base_url },
        "request": request,
      })
      let url = "\{model.base_url}/chat/completions"
      let uri = Uri::parse(url)
      // Check if this is an agent call (has tool/assistant messages)
      let is_agent_call = request.messages
        .iter()
        .any(fn(msg) {
          match msg {
            Tool(_) | Assistant(_) => true
            _ => false
          }
        })
      let client = @http.Client::new("\{uri.schema}://\{uri.host}", headers={
        "Authorization": "Bearer \{current_token.val}",
        "Content-Type": "application/json",
        "Connection": "close",
        "User-Agent": "GitHubCopilotChat/0.32.4",
        "Editor-Version": "vscode/1.105.1",
        "Editor-Plugin-Version": "copilot-chat/0.32.4",
        "Copilot-Integration-Id": "vscode-chat",
        "Openai-Intent": "conversation-edits",
        "X-Initiator": if is_agent_call {
          "agent"
        } else {
          "user"
        },
      })
      defer client.close()
      let body = request.to_json()
      let response = client.post(uri.path, body)
      guard response.code is (200..=299) else {
        let error_body = client.read_all().text()
        // Try to refresh token on 401
        if response.code == 401 && not(has_refreshed.val) {
          has_refreshed.val = true // Mark as refreshed to prevent infinite loop
          logger.info("Received 401, attempting to refresh Copilot token")
          let refresh_result : @copilot.Credentials? = Some(
            @copilot.refresh_and_save_credentials(),
          ) catch {
            _ => None
          }
          match refresh_result {
            Some(refreshed) => {
              current_token.val = refreshed.copilot_token
              logger.info(
                "Copilot token refreshed successfully, retrying request",
              )
            }
            None => {
              logger.info("Copilot refresh failed, triggering re-login flow")
              let new_creds = @copilot.start_oauth_flow() catch {
                login_err => {
                  logger.error("Copilot re-login failed", data={
                    "error": login_err.to_string(),
                  })
                  raise HttpError(
                    code=401,
                    body="Copilot re-login failed: \{login_err}",
                  )
                }
              }
              current_token.val = new_creds.copilot_token
              logger.info("Copilot re-login successful, retrying request")
            }
          }
          raise HttpError(code=response.code, body=error_body)
        }
        raise HttpError(code=response.code, body=error_body)
      }
      if request.stream is Some(true) {
        let reader = ChunkReader::new(client)
        let builder = ChatCompletionBuilder::new()
        while reader.read() is Some(chunk) {
          builder.add_chunk(chunk)
        }
        builder.to_chat_completion()
      } else {
        let body = client.read_all().text()
        let json = @json.parse(body)
        @json.from_json(json)
      }
    },
  )
}

///|
fn convert_tools_to_responses_api(
  tools : Array[ChatCompletionToolParam],
) -> Array[Json] {
  tools.map(fn(tool) {
    match tool {
      Function(func_def) =>
        {
          "type": "function",
          "name": func_def.name,
          "description": func_def.description,
          "parameters": func_def.parameters,
        }
    }
  })
}

///|
priv struct CodexStreamResult {
  text_chunks : Array[String]
  output_items : Array[@responses.ResponseItem]
}

///|
async fn do_codex_stream_request(
  access_token : String,
  account_id : String,
  request : @responses.ResponsesRequest,
) -> CodexStreamResult raise Error {
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
    raise HttpError(code=500, body="Invalid request body")
  }
  body_obj["stream"] = true
  let response = client.post(
    "/backend-api/codex/responses",
    Json::object(body_obj),
  )
  guard response.code is (200..=299) else {
    let error_text = client.read_all().text()
    raise HttpError(
      code=response.code,
      body="API request failed: \{error_text}",
    )
  }
  let reader = ResponseStreamEventReader::new(client)
  let text_chunks : Array[String] = []
  let output_items : Array[@responses.ResponseItem] = []
  while reader.read() is Some(event) {
    match event {
      TextDelta(delta) => text_chunks.push(delta)
      OutputItemDone(item) => output_items.push(item)
      Completed => break
    }
  }
  { text_chunks, output_items }
}

///|
priv enum ResponseStreamEvent {
  TextDelta(String)
  OutputItemDone(@responses.ResponseItem)
  Completed
}

///|
priv struct ResponseStreamEventReader(&@io.Reader)

///|
fn ResponseStreamEventReader::new(
  reader : &@io.Reader,
) -> ResponseStreamEventReader {
  ResponseStreamEventReader(reader)
}

///|
async fn ResponseStreamEventReader::read(
  self : ResponseStreamEventReader,
) -> ResponseStreamEvent? {
  for {
    guard self.0.read_until("\n") is Some(line) else { return None }
    guard line is [.. "data: ", .. rest] else { continue }
    let data = rest.trim().to_string()
    if data == "[DONE]" {
      return Some(Completed)
    }
    try {
      let json = @json.parse(data)
      guard json is Object(obj) else { continue }
      guard obj.get("type") is Some(String(event_type)) else { continue }
      match event_type {
        "response.output_text.delta" =>
          if obj.get("delta") is Some(String(delta)) {
            return Some(TextDelta(delta))
          }
        "response.content_part.delta" =>
          if obj.get("delta") is Some(Object(delta_obj)) {
            if delta_obj.get("text") is Some(String(text)) {
              return Some(TextDelta(text))
            }
          }
        "response.output_item.done" =>
          if obj.get("item") is Some(item_json) {
            try {
              let item : @responses.ResponseItem = @json.from_json(item_json)
              return Some(OutputItemDone(item))
            } catch {
              _ => continue
            }
          }
        "response.completed" => return Some(Completed)
        _ => continue
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
fn convert_messages_to_input(
  messages : Array[ChatCompletionMessageParam],
) -> Array[@responses.ResponseInputItem] {
  let result : Array[@responses.ResponseInputItem] = []
  for msg in messages {
    match msg {
      System(_) => continue
      User(user_msg) => {
        let text = extract_text_content(user_msg.content)
        result.push(@responses.message_input(role="user", content=text))
      }
      Assistant(assistant_msg) => {
        let text = extract_text_content(assistant_msg.content)
        if !text.is_empty() {
          result.push(@responses.message_input(role="assistant", content=text))
        }
        for tc in assistant_msg.tool_calls {
          result.push(
            @responses.ResponseInputItem::FunctionCall(
              call_id=tc.id,
              name=tc.function.name,
              arguments=tc.function.arguments.unwrap_or("{}"),
            ),
          )
        }
      }
      Tool(tool_msg) => {
        let text = extract_text_content(tool_msg.content)
        result.push(
          @responses.function_call_output(
            call_id=tool_msg.tool_call_id,
            output=text,
          ),
        )
      }
    }
  }
  result
}

///|
fn codex_stream_result_to_chat_completion(
  model_name : String,
  result : CodexStreamResult,
) -> ChatCompletion {
  let mut content : String? = None
  let tool_calls : Array[ChatCompletionMessageToolCall] = []
  for item in result.output_items {
    match item {
      @responses.ResponseItem::Message(content=parts, ..) => {
        let texts = parts.map(fn(part) { part.text })
        let text = texts
          .iter()
          .fold(init="", fn(acc, t) {
            if acc.is_empty() {
              t
            } else {
              "\{acc}\n\{t}"
            }
          })
        content = Some(text)
      }
      @responses.ResponseItem::FunctionCall(call_id~, name~, arguments~) =>
        tool_calls.push(tool_call(id=call_id, name~, arguments~))
    }
  }
  if content is None && !result.text_chunks.is_empty() {
    content = Some(
      result.text_chunks.iter().fold(init="", fn(acc, c) { acc + c }),
    )
  }
  let finish_reason = if tool_calls.is_empty() { Stop } else { ToolCalls }
  ChatCompletion::new(
    id="codex-response",
    choices=[
      ChatCompletionChoice::new(
        index=0,
        message=ChatCompletionMessage::new(content?, tool_calls~),
        finish_reason~,
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
