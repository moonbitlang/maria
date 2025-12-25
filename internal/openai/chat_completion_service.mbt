///|
struct ChatCompletionService {
  client : Client
}

///|
fn ChatCompletionService::new(client : Client) -> ChatCompletionService {
  ChatCompletionService::{ client, }
}

///|
pub async fn ChatCompletionService::create(
  self : ChatCompletionService,
  model~ : String,
  messages : Array[ChatCompletionMessageParam],
  usage? : CompletionUsageParam,
  user? : String,
  max_tokens? : Int,
  temperature? : Double,
  response_format? : ResponseFormat,
  tool_choice? : ChatCompletionToolChoice,
) -> ChatCompletion {
  let request = chat_completion(
    model~,
    messages~,
    usage?,
    user?,
    max_tokens?,
    temperature?,
    response_format?,
    tool_choice?,
  )
  let (r, b) = self.client.post("/chat/completions", request.to_json())
  guard r.code is (200..=299) else {
    raise HttpError(code=r.code, body=b.text())
  }
  @json.from_json(b.json())
}

///|
pub async fn ChatCompletionService::stream(
  self : ChatCompletionService,
  model~ : String,
  messages : Array[ChatCompletionMessageParam],
  usage? : CompletionUsageParam,
  user? : String,
  max_tokens? : Int,
  temperature? : Double,
  response_format? : ResponseFormat,
  stream_options? : ChatCompletionStreamOptionsParam,
  tool_choice? : ChatCompletionToolChoice,
) -> ChunkReader {
  let request = chat_completion(
    model~,
    messages~,
    usage?,
    user?,
    max_tokens?,
    temperature?,
    response_format?,
    stream=true,
    stream_options?,
    tool_choice?,
  )
  let (r, b) = self.client.post_stream("/chat/completions", request.to_json())
  guard r.code is (200..=299) else {
    raise HttpError(code=r.code, body=b.read_all().text())
  }
  ChunkReader::new(b)
}
