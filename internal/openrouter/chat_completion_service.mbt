///|
priv struct Client {
  base_url : String
  api_key : String
}

///|
const BaseUrl = "https://openrouter.ai/api/v1"

///|
fn Client::new(base_url? : String = BaseUrl, api_key~ : String) -> Client {
  Client::{ base_url, api_key }
}

///|
pub struct OpenRouter {
  chat : ChatService
}

///|
pub fn OpenRouter::new(api_key~ : String) -> OpenRouter {
  let client = Client::new(api_key~)
  OpenRouter::{ chat: ChatService::new(client) }
}

///|
async fn Client::request(
  self : Client,
  path : String,
  body : Json,
) -> (@http.Response, Json) {
  let url = "\{self.base_url}\{path}"
  let (r, b) = @http.post(url, body, headers={
    "Authorization": "Bearer \{self.api_key}",
    "Content-Type": "application/json",
  })
  (r, b.json())
}

///|
pub struct ChatService {
  completion : ChatCompletionService
}

///|
fn ChatService::new(client : Client) -> ChatService {
  ChatService::{ completion: ChatCompletionService::new(client) }
}

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
  provider? : ChatGenerationParamsProvider,
  plugins? : Array[ChatGenerationParamsPlugin],
  route? : ChatGenerationParamsRoute,
  user? : String,
  session_id? : String,
  messages~ : Array[Message],
  model? : String,
  models? : Array[String],
  frequency_penalty? : Float,
  logit_bias? : Map[String, Float],
  logprobs? : Bool,
  top_logprobs? : Int,
  max_completion_tokens? : Int,
  max_tokens? : Int,
  metadata? : Map[String, String],
  presence_penalty? : Float,
  reasoning? : Reasoning,
  response_format? : ChatGenerationParamsResponseFormat,
  seed? : Int,
  stop? : Array[String],
  temperature? : Float,
  tool_choice? : Json,
  tools? : Array[ToolDefinitionJson],
  top_p? : Float,
  debug? : Debug,
) -> ChatResponse {
  let request : ChatGenerationParams = ChatGenerationParams::{
    provider,
    plugins,
    route,
    user,
    session_id,
    messages,
    model,
    models,
    frequency_penalty,
    logit_bias,
    logprobs,
    top_logprobs,
    max_completion_tokens,
    max_tokens,
    metadata,
    presence_penalty,
    reasoning,
    response_format,
    seed,
    stop,
    temperature,
    tool_choice,
    tools,
    top_p,
    debug,
  }
  let (r, b) = self.client.request("/chat/completions", request.to_json())
  match r.code {
    200 => @json.from_json(b)
    400 => raise ChatCompletionError::BadRequest(@json.from_json(b))
    401 => raise ChatCompletionError::Unauthorized(@json.from_json(b))
    429 => raise ChatCompletionError::TooManyRequests(@json.from_json(b))
    500 => raise ChatCompletionError::InternalServerError(@json.from_json(b))
    code => raise ChatCompletionError::UnknownError(code, @json.from_json(b))
  }
}
