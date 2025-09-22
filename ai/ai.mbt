///|
async fn[T] with_retry(
  backoff_multiplier~ : Int,
  delay_ms~ : Int,
  max_delay_ms~ : Int,
  max_retries~ : Int,
  f : async () -> T,
) -> T {
  guard max_retries > 0
  let errors : Array[Error] = []
  let mut delay_ms = delay_ms
  for attempt in 0..<max_retries {
    try {
      return f()
    } catch {
      (error : Error) => {
        errors.push(error)
        continue
      }
    }
    delay_ms = @cmp.minimum(delay_ms * backoff_multiplier, max_delay_ms)
  }
  raise errors.last().unwrap()
}

///|
priv suberror HttpError {
  HttpError(code~ : Int, body~ : String)
} derive(Show)

///|
pub async fn chat(
  model~ : @model.Model,
  request : @openai.ChatCompletionParam,
) -> @openai.ChatCompletion {
  let request_body = request.to_json().stringify()
  let (response, response_body) = with_retry(
    backoff_multiplier=2,
    delay_ms=1000,
    max_delay_ms=16000,
    max_retries=5,
    () => @http.post(
      @encoding/utf8.encode("\{model.base_url}/chat/completions"),
      @encoding/utf8.encode(request_body),
      headers=[
        @http.Header(
          "Authorization",
          @encoding/utf8.encode("Bearer \{model.api_key}"),
        ),
        @http.Header("Content-Type", "application/json"),
        @http.Header("Connection", "close"),
      ],
    ),
  )
  guard response.code is (200..=299) else {
    raise HttpError(
      code=response.code,
      body=@encoding/utf8.decode_lossy(response_body),
    )
  }
  response_body |> @encoding/utf8.decode() |> @json.parse() |> @json.from_json()
}

///|
pub async fn text(model~ : @model.Model, prompt~ : String) -> String {
  let completion = chat(
    model~,
    @openai.chat_completion(
      model=model.name,
      messages=[
        @openai.system_message(content="You are a helpful assistant."),
        @openai.user_message(content=prompt),
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
    .map(s => s.trim(" \r\n\t").to_string()))
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
pub async fn json(model~ : @model.Model, prompt~ : String) -> Json {
  let completion = chat(
    model~,
    @openai.chat_completion(
      model=model.name,
      messages=[
        @openai.system_message(content="You are a helpful assistant."),
        @openai.user_message(content=prompt),
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
pub(open) trait Structural: @json.FromJson {
  name() -> String
  description() -> String
  schema() -> @schema.Schema
}

///|
pub async fn[T : Structural] data(model~ : @model.Model, prompt~ : String) -> T {
  let completion = chat(
    model~,
    @openai.chat_completion(
      model=model.name,
      messages=[
        @openai.system_message(content="You are a helpful assistant."),
        @openai.user_message(content=prompt),
      ],
      max_tokens=150,
      temperature=0.7,
      response_format=@openai.json_schema(
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
