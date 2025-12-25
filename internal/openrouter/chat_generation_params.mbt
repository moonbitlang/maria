///|
struct ChatGenerationParams {
  provider : ChatGenerationParamsProvider?
  plugins : Array[ChatGenerationParamsPlugin]?
  route : ChatGenerationParamsRoute?
  user : String?
  session_id : String?
  messages : Array[@message.Message]
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
  let object : Map[String, Json] = { "messages": self.messages.to_json() }
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

///|
pub impl @json.FromJson for ChatGenerationParams with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParams raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParams::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let messages : Array[@message.Message] = match object.get("messages") {
    Some(v) => @json.from_json(v, path=path.add_key("messages"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("messages"), "\{func_name}: missing field messages"),
      )
  }
  let provider : ChatGenerationParamsProvider? = match object.get("provider") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("provider")))
  }
  let plugins : Array[ChatGenerationParamsPlugin]? = match
    object.get("plugins") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("plugins")))
  }
  let route : ChatGenerationParamsRoute? = match object.get("route") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("route")))
  }
  let user : String? = match object.get("user") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("user")))
  }
  let session_id : String? = match object.get("session_id") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("session_id")))
  }
  let model : String? = match object.get("model") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("model")))
  }
  let models : Array[String]? = match object.get("models") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("models")))
  }
  let frequency_penalty : Float? = match object.get("frequency_penalty") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("frequency_penalty")))
  }
  let logit_bias : Map[String, Float]? = match object.get("logit_bias") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("logit_bias")))
  }
  let logprobs : Bool? = match object.get("logprobs") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("logprobs")))
  }
  let top_logprobs : Int? = match object.get("top_logprobs") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("top_logprobs")))
  }
  let max_completion_tokens : Int? = match object.get("max_completion_tokens") {
    None | Some(Null) => None
    Some(v) =>
      Some(@json.from_json(v, path=path.add_key("max_completion_tokens")))
  }
  let max_tokens : Int? = match object.get("max_tokens") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("max_tokens")))
  }
  let metadata : Map[String, String]? = match object.get("metadata") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("metadata")))
  }
  let presence_penalty : Float? = match object.get("presence_penalty") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("presence_penalty")))
  }
  let reasoning : Reasoning? = match object.get("reasoning") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("reasoning")))
  }
  let response_format : ChatGenerationParamsResponseFormat? = match
    object.get("response_format") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("response_format")))
  }
  let seed : Int? = match object.get("seed") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("seed")))
  }
  let stop : Array[String]? = match object.get("stop") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("stop")))
  }
  let temperature : Float? = match object.get("temperature") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("temperature")))
  }
  let tool_choice : Json? = match object.get("tool_choice") {
    None | Some(Null) => None
    Some(v) => Some(v)
  }
  let tools : Array[ToolDefinitionJson]? = match object.get("tools") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("tools")))
  }
  let top_p : Float? = match object.get("top_p") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("top_p")))
  }
  let debug : Debug? = match object.get("debug") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("debug")))
  }
  ChatGenerationParams::{
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
}
