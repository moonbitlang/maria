///|
struct ChatGenerationParams {
  provider : ChatGenerationParamsProvider?
  plugins : Array[ChatGenerationParamsPlugin]?
  route : ChatGenerationParamsRoute?
  user : String?
  session_id : String?
  messages : Array[Message]
  model : String?
  models : Array[String]?
  frequency_penalty : Float?
  logit_bias : Map[String, Float]?
  logprobs : Bool?
  top_logprobs : Int?
  max_completion_tokens : Int?
  max_tokens : Int?
  metadata : Map[String, String]?
  presence_penalty : Float?
  reasoning : Reasoning?
  response_format : ChatGenerationParamsResponseFormat?
  seed : Int?
  stop : Array[String]?
  stream : Bool
  stream_options : ChatStreamOptions?
  temperature : Float?
  tool_choice : Json?
  tools : Array[ToolDefinitionJson]?
  top_p : Float?
  debug : Debug?
}

///|
pub impl ToJson for ChatGenerationParams with to_json(
  self : ChatGenerationParams,
) -> Json {
  let object : Map[String, Json] = {
    "messages": self.messages.to_json(),
    "stream": self.stream.to_json(),
  }
  if self.provider is Some(provider) {
    object["provider"] = provider.to_json()
  }
  if self.plugins is Some(plugins) {
    object["plugins"] = plugins.to_json()
  }
  if self.route is Some(route) {
    object["route"] = route.to_json()
  }
  if self.user is Some(user) {
    object["user"] = user.to_json()
  }
  if self.session_id is Some(session_id) {
    object["session_id"] = session_id.to_json()
  }
  if self.model is Some(model) {
    object["model"] = model.to_json()
  }
  if self.models is Some(models) {
    object["models"] = models.to_json()
  }
  if self.frequency_penalty is Some(frequency_penalty) {
    object["frequency_penalty"] = frequency_penalty.to_json()
  }
  if self.logit_bias is Some(logit_bias) {
    object["logit_bias"] = logit_bias.to_json()
  }
  if self.logprobs is Some(logprobs) {
    object["logprobs"] = logprobs.to_json()
  }
  if self.top_logprobs is Some(top_logprobs) {
    object["top_logprobs"] = top_logprobs.to_json()
  }
  if self.max_completion_tokens is Some(max_completion_tokens) {
    object["max_completion_tokens"] = max_completion_tokens.to_json()
  }
  if self.max_tokens is Some(max_tokens) {
    object["max_tokens"] = max_tokens.to_json()
  }
  if self.metadata is Some(metadata) {
    object["metadata"] = metadata.to_json()
  }
  if self.presence_penalty is Some(presence_penalty) {
    object["presence_penalty"] = presence_penalty.to_json()
  }
  if self.reasoning is Some(reasoning) {
    object["reasoning"] = reasoning.to_json()
  }
  if self.response_format is Some(response_format) {
    object["response_format"] = response_format.to_json()
  }
  if self.seed is Some(seed) {
    object["seed"] = seed.to_json()
  }
  if self.stop is Some(stop) {
    object["stop"] = stop.to_json()
  }
  if self.stream_options is Some(stream_options) {
    object["stream_options"] = stream_options.to_json()
  }
  if self.temperature is Some(temperature) {
    object["temperature"] = temperature.to_json()
  }
  if self.tool_choice is Some(tool_choice) {
    object["tool_choice"] = tool_choice
  }
  if self.tools is Some(tools) {
    object["tools"] = tools.to_json()
  }
  if self.top_p is Some(top_p) {
    object["top_p"] = top_p.to_json()
  }
  if self.debug is Some(debug) {
    object["debug"] = debug.to_json()
  }
  Json::object(object)
}
