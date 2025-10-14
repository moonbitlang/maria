///|
priv suberror HttpError {
  HttpError(code~ : Int, body~ : String)
} derive(Show)

///|
pub async fn chat(
  model~ : @model.Model,
  request : @openai.ChatCompletionParam,
) -> @openai.ChatCompletion {
  let (response, response_body) = @async.retry(
    ExponentialDelay(initial=1000, factor=2.0, maximum=16000),
    max_retry=5,
    () => @http.post("\{model.base_url}/chat/completions", request.to_json(), headers={
      "Authorization": "Bearer \{model.api_key}",
      "Content-Type": "application/json",
      "Connection": "close",
    }),
  )
  guard response.code is (200..=299) else {
    raise HttpError(code=response.code, body=response_body.text())
  }
  response_body.json() |> @json.from_json()
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
