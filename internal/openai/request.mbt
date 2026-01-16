///|
/// Parameters accepted by the chat completion endpoint.
/// This is the request type
/// ```mbt no check
/// let uri = Uri::parse(url)
/// let client = @http.Client::connect(uri.host, protocol=uri.protocol, headers={
///   "Authorization": "Bearer \{model.api_key}",
///   "Content-Type": "application/json",
///   "Connection": "close",
/// })
/// defer client.close()
/// let response = client.post(uri.path, (request : ChatCompletionParam).to_json())
/// ```
pub struct Request {
  model : String
  messages : Array[ChatCompletionMessageParam]
  tools : Array[ChatCompletionToolParam]
  usage : CompletionUsageParam?
  user : String?
  max_tokens : Int?
  temperature : Double?
  reasoning_effort : ChatCompletionReasoningEffort?
  response_format : ResponseFormat?
  stream : Bool?
  stream_options : ChatCompletionStreamOptionsParam?
  tool_choice : ChatCompletionToolChoice?
}

///|
pub impl ToJson for Request with to_json(self : Request) -> Json {
  let json : Map[String, Json] = {
    "model": Json::string(self.model),
    "messages": self.messages,
  }
  if !self.tools.is_empty() {
    json["tools"] = self.tools.to_json()
  }
  if self.usage is Some(usage) {
    json["usage"] = usage.to_json()
  }
  if self.user is Some(user) {
    json["user"] = Json::string(user)
  }
  if self.max_tokens is Some(max_tokens) {
    json["max_tokens"] = max_tokens.to_json()
  }
  if self.temperature is Some(temperature) {
    json["temperature"] = temperature.to_json()
  }
  if self.reasoning_effort is Some(reasoning_effort) {
    json["reasoning_effort"] = reasoning_effort.to_json()
  }
  if self.response_format is Some(response_format) {
    json["response_format"] = response_format.to_json()
  }
  if self.stream is Some(stream) {
    json["stream"] = stream.to_json()
  }
  if self.stream_options is Some(stream_options) {
    json["stream_options"] = stream_options.to_json()
  }
  Json::object(json)
}
