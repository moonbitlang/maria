///|
pub enum ChatCompletionServiceTier {
  Auto
  Default
  Flex
  Scale
  Priority
} derive(Show)

///|
impl @json.FromJson for ChatCompletionServiceTier with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionServiceTier {
  guard json is String(tier) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match tier {
    "auto" => ChatCompletionServiceTier::Auto
    "default" => ChatCompletionServiceTier::Default
    "flex" => ChatCompletionServiceTier::Flex
    "scale" => ChatCompletionServiceTier::Scale
    "priority" => ChatCompletionServiceTier::Priority
    _ =>
      raise @json.JsonDecodeError((json_path, "Unknown service tier: \{tier}"))
  }
}

///|
typealias ChatCompletionServiceTier as ChatCompletionChunkServiceTier

///|
pub struct ChatCompletionChoiceLogprobs {
  content : Array[ChatCompletionTokenLogprob]?
  refusal : Array[ChatCompletionTokenLogprob]?
} derive(Show)

///|
impl @json.FromJson for ChatCompletionChoiceLogprobs with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChoiceLogprobs {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let content = match json.get("content") {
    Some(Null) => None
    Some(content) => {
      let content : Array[ChatCompletionTokenLogprob] = @json.from_json(
        content,
        path=json_path.add_key("content"),
      )
      Some(content)
    }
    None => None
  }
  let refusal = match json.get("refusal") {
    Some(Null) => None
    Some(refusal) => {
      let refusal : Array[ChatCompletionTokenLogprob] = @json.from_json(
        refusal,
        path=json_path.add_key("refusal"),
      )
      Some(refusal)
    }
    None => None
  }
  ChatCompletionChoiceLogprobs::{ content, refusal }
}

///|
/// Token logprob information
pub struct ChatCompletionTokenLogprob {
  token : String
  logprob : Double
  bytes : Array[Int]?
  top_logprobs : Array[ChatCompletionTopLogprob]
} derive(Show)

///|
impl @json.FromJson for ChatCompletionTokenLogprob with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionTokenLogprob {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("token") is Some(String(token)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'token' field"))
  }
  guard json.get("logprob") is Some(Number(logprob, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'logprob' field"))
  }
  let bytes = match json.get("bytes") {
    Some(Null) => None
    Some(bytes) => {
      let bytes : Array[Int] = @json.from_json(
        bytes,
        path=json_path.add_key("bytes"),
      )
      Some(bytes)
    }
    None => None
  }
  guard json.get("top_logprobs") is Some(top_logprobs) else {
    raise @json.JsonDecodeError((json_path, "Missing 'top_logprobs' field"))
  }
  let top_logprobs : Array[ChatCompletionTopLogprob] = @json.from_json(
    top_logprobs,
    path=json_path.add_key("top_logprobs"),
  )
  ChatCompletionTokenLogprob::{ token, logprob, bytes, top_logprobs }
}

///|
/// Top logprob information
pub struct ChatCompletionTopLogprob {
  token : String
  logprob : Double
  bytes : Array[Int]?
} derive(Show)

///|
impl @json.FromJson for ChatCompletionTopLogprob with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionTopLogprob {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("token") is Some(String(token)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'token' field"))
  }
  guard json.get("logprob") is Some(Number(logprob, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'logprob' field"))
  }
  let bytes = match json.get("bytes") {
    Some(Null) => None
    Some(bytes) => {
      let bytes : Array[Int] = @json.from_json(
        bytes,
        path=json_path.add_key("bytes"),
      )
      Some(bytes)
    }
    None => None
  }
  ChatCompletionTopLogprob::{ token, logprob, bytes }
}

///|
pub struct Function {
  arguments : String
  name : String
} derive(Show)

///|
impl ToJson for Function with to_json(self : Function) -> Json {
  { "name": self.name, "arguments": self.arguments }
}

///|
impl @json.FromJson for Function with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Function {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("arguments") is Some(String(arguments)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'arguments' field"))
  }
  guard json.get("name") is Some(String(name)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'name' field"))
  }
  Function::{ arguments, name }
}

///|
pub struct ChatCompletionMessageToolCall {
  id : String
  function : Function
} derive(Show)

///|
impl ToJson for ChatCompletionMessageToolCall with to_json(
  self : ChatCompletionMessageToolCall,
) -> Json {
  { "id": self.id, "function": self.function, "type": "function" }
}

///|
impl @json.FromJson for ChatCompletionMessageToolCall with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageToolCall {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("id") is Some(String(id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'id' field"))
  }
  guard json.get("function") is Some(function) else {
    raise @json.JsonDecodeError((json_path, "Missing 'function' field"))
  }
  let function : Function = @json.from_json(
    function,
    path=json_path.add_key("function"),
  )
  ChatCompletionMessageToolCall::{ id, function }
}

///|
pub struct ChatCompletionMessage {
  content : String?
  refusal : String?
  tool_calls : Array[ChatCompletionMessageToolCall]
  function_call : ChatCompletionMessageFunctionCall?
} derive(Show)

///|
/// Deprecated function call format (replaced by tool_calls)
pub struct ChatCompletionMessageFunctionCall {
  arguments : String
  name : String
} derive(Show)

///|
impl @json.FromJson for ChatCompletionMessageFunctionCall with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageFunctionCall {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("arguments") is Some(String(arguments)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'arguments' field"))
  }
  guard json.get("name") is Some(String(name)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'name' field"))
  }
  ChatCompletionMessageFunctionCall::{ arguments, name }
}

///|
impl ToJson for ChatCompletionMessageFunctionCall with to_json(
  self : ChatCompletionMessageFunctionCall,
) -> Json {
  { "arguments": self.arguments, "name": self.name }
}

///|
pub fn ChatCompletionMessage::to_param(
  self : ChatCompletionMessage,
) -> ChatCompletionMessageParam {
  let parts = []
  if self.content is Some(content) {
    parts.push(text_content_part(content))
  }
  Assistant({
    content: parts,
    name: None,
    tool_calls: self.tool_calls,
    function_call: self.function_call,
  })
}

///|
impl @json.FromJson for ChatCompletionMessage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessage {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let content = match json.get("content") {
    Some(Null) => None
    Some(content) => {
      let content : String = @json.from_json(
        content,
        path=json_path.add_key("content"),
      )
      Some(content)
    }
    None => None
  }
  let refusal = match json.get("refusal") {
    Some(Null) => None
    Some(refusal) => {
      let refusal : String = @json.from_json(
        refusal,
        path=json_path.add_key("refusal"),
      )
      Some(refusal)
    }
    None => None
  }
  let tool_calls = match json.get("tool_calls") {
    Some(tool_calls) => {
      let tool_calls : Array[ChatCompletionMessageToolCall] = @json.from_json(
        tool_calls,
        path=json_path.add_key("tool_calls"),
      )
      tool_calls
    }
    None => []
  }
  let function_call = match json.get("function_call") {
    Some(Null) => None
    Some(function_call) => {
      let function_call : ChatCompletionMessageFunctionCall = @json.from_json(
        function_call,
        path=json_path.add_key("function_call"),
      )
      Some(function_call)
    }
    None => None
  }
  ChatCompletionMessage::{ content, refusal, tool_calls, function_call }
}

///|
pub enum ChatCompletionChoiceFinishReason {
  Stop
  Length
  ToolCalls
  ContentFilter
  FunctionCall
} derive(Show)

///|
impl @json.FromJson for ChatCompletionChoiceFinishReason with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChoiceFinishReason {
  guard json is String(reason) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match reason {
    "stop" => ChatCompletionChoiceFinishReason::Stop
    "length" => ChatCompletionChoiceFinishReason::Length
    "tool_calls" => ChatCompletionChoiceFinishReason::ToolCalls
    "content_filter" => ChatCompletionChoiceFinishReason::ContentFilter
    "function_call" => ChatCompletionChoiceFinishReason::FunctionCall
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown finish reason: \{reason}"),
      )
  }
}

///|
pub struct ChatCompletionChoice {
  finish_reason : ChatCompletionChoiceFinishReason
  index : Int
  message : ChatCompletionMessage
  logprobs : ChatCompletionChoiceLogprobs?
} derive(Show)

///|
impl @json.FromJson for ChatCompletionChoice with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChoice {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("finish_reason") is Some(finish_reason) else {
    raise @json.JsonDecodeError((json_path, "Missing 'finish_reason' field"))
  }
  let finish_reason : ChatCompletionChoiceFinishReason = @json.from_json(
    finish_reason,
    path=json_path.add_key("finish_reason"),
  )
  guard json.get("index") is Some(Number(index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'index' field"))
  }
  guard json.get("message") is Some(message) else {
    raise @json.JsonDecodeError((json_path, "Missing 'message' field"))
  }
  let message : ChatCompletionMessage = @json.from_json(
    message,
    path=json_path.add_key("message"),
  )
  let logprobs = match json.get("logprobs") {
    Some(Null) => None
    Some(logprobs) => {
      let logprobs : ChatCompletionChoiceLogprobs = @json.from_json(
        logprobs,
        path=json_path.add_key("logprobs"),
      )
      Some(logprobs)
    }
    None => None
  }
  ChatCompletionChoice::{
    finish_reason,
    index: index.to_int(),
    message,
    logprobs,
  }
}

///|
pub struct CompletionTokensDetails {
  reasoning_tokens : Int?
} derive(Show, ToJson)

///|
impl @json.FromJson for CompletionTokensDetails with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CompletionTokensDetails {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let reasoning_tokens = match json.get("reasoning_tokens") {
    Some(Null) => None
    Some(Number(reasoning_tokens, ..)) => Some(reasoning_tokens.to_int())
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'reasoning_tokens' to be a number"),
      )
    None => None
  }
  CompletionTokensDetails::{ reasoning_tokens, }
}

///|
pub struct CostDetails {
  upstream_inference_cost : Double?
} derive(Show, ToJson)

///|
impl @json.FromJson for CostDetails with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CostDetails {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let upstream_inference_cost = match json.get("upstream_inference_cost") {
    Some(Null) => None
    Some(Number(upstream_inference_cost, ..)) => Some(upstream_inference_cost)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'upstream_inference_cost' to be a number"),
      )
    None => None
  }
  CostDetails::{ upstream_inference_cost, }
}

///|
pub struct PromptTokensDetails {
  cached_tokens : Int?
  audio_tokens : Int?
} derive(Show, ToJson)

///|
impl @json.FromJson for PromptTokensDetails with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> PromptTokensDetails {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let cached_tokens = match json.get("cached_tokens") {
    Some(Null) => None
    Some(Number(cached_tokens, ..)) => Some(cached_tokens.to_int())
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'cached_tokens' to be a number"),
      )
    None => None
  }
  let audio_tokens = match json.get("audio_tokens") {
    Some(Null) => None
    Some(Number(audio_tokens, ..)) => Some(audio_tokens.to_int())
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'audio_tokens' to be a number"),
      )
    None => None
  }
  PromptTokensDetails::{ cached_tokens, audio_tokens }
}

///|
pub struct CompletionUsage {
  completion_tokens : Int
  completion_tokens_details : CompletionTokensDetails?
  cost : Double?
  cost_details : CostDetails?
  prompt_tokens : Int
  prompt_tokens_details : PromptTokensDetails?
  total_tokens : Int
} derive(Show, ToJson)

///|
impl @json.FromJson for CompletionUsage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> CompletionUsage {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("completion_tokens") is Some(Number(completion_tokens, ..)) else {
    raise @json.JsonDecodeError(
      (json_path, "Missing 'completion_tokens' field"),
    )
  }
  let completion_tokens_details = match json.get("completion_tokens_details") {
    Some(Null) => None
    Some(details) => {
      let details : CompletionTokensDetails = @json.from_json(
        details,
        path=json_path.add_key("completion_tokens_details"),
      )
      Some(details)
    }
    None => None
  }
  let cost = match json.get("cost") {
    Some(Null) => None
    Some(Number(cost, ..)) => Some(cost)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'cost' to be a number"))
    None => None
  }
  let cost_details = match json.get("cost_details") {
    Some(Null) => None
    Some(details) => {
      let details : CostDetails = @json.from_json(
        details,
        path=json_path.add_key("cost_details"),
      )
      Some(details)
    }
    None => None
  }
  guard json.get("prompt_tokens") is Some(Number(prompt_tokens, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'prompt_tokens' field"))
  }
  let prompt_tokens_details = match json.get("prompt_tokens_details") {
    Some(Null) => None
    Some(details) => {
      let details : PromptTokensDetails = @json.from_json(
        details,
        path=json_path.add_key("prompt_tokens_details"),
      )
      Some(details)
    }
    None => None
  }
  guard json.get("total_tokens") is Some(Number(total_tokens, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'total_tokens' field"))
  }
  CompletionUsage::{
    completion_tokens: completion_tokens.to_int(),
    completion_tokens_details,
    cost,
    cost_details,
    prompt_tokens: prompt_tokens.to_int(),
    prompt_tokens_details,
    total_tokens: total_tokens.to_int(),
  }
}

///|
pub struct CompletionUsageParam {
  include_ : Bool
}

///|
pub fn usage(include_~ : Bool) -> CompletionUsageParam {
  CompletionUsageParam::{ include_, }
}

///|
impl ToJson for CompletionUsageParam with to_json(self : CompletionUsageParam) -> Json {
  { "include": Json::boolean(self.include_) }
}

///|
pub struct ChatCompletionParam {
  model : String
  messages : Array[ChatCompletionMessageParam]
  tools : Array[ChatCompletionToolParam]
  usage : CompletionUsageParam?
  user : String?
}

///|
pub fn chat_completion(
  model~ : String,
  messages~ : Array[ChatCompletionMessageParam],
  tools? : Array[ChatCompletionToolParam] = [],
  usage? : CompletionUsageParam,
  user? : String,
) -> ChatCompletionParam {
  ChatCompletionParam::{ model, messages, tools, usage, user }
}

///|
pub impl ToJson for ChatCompletionParam with to_json(self : ChatCompletionParam) -> Json {
  let json : Map[String, Json] = {
    "model": Json::string(self.model),
    "messages": self.messages.to_json(),
  }
  if !self.tools.is_empty() {
    json["tools"] = self.tools.to_json()
  }
  if self.usage is Some(usage) {
    json["usage"] = usage.to_json()
  }
  Json::object(json)
}

///|
pub struct ChatCompletion {
  id : String
  choices : Array[ChatCompletionChoice]
  created : Int
  model : String
  usage : CompletionUsage?
  system_fingerprint : String?
  service_tier : ChatCompletionServiceTier?
} derive(Show)

///|
pub impl @json.FromJson for ChatCompletion with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletion {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("id") is Some(String(id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'id' field"))
  }
  guard json.get("choices") is Some(choices) else {
    raise @json.JsonDecodeError((json_path, "Missing 'choices' field"))
  }
  let choices : Array[ChatCompletionChoice] = @json.from_json(
    choices,
    path=json_path.add_key("choices"),
  )
  guard json.get("created") is Some(Number(created, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'created' field"))
  }
  guard json.get("model") is Some(String(model)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'model' field"))
  }
  let usage = match json.get("usage") {
    Some(Null) => None
    Some(usage) => {
      let usage : CompletionUsage = @json.from_json(
        usage,
        path=json_path.add_key("usage"),
      )
      Some(usage)
    }
    None => None
  }
  let system_fingerprint = match json.get("system_fingerprint") {
    Some(Null) => None
    Some(String(fingerprint)) => Some(fingerprint)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'system_fingerprint' to be a string"),
      )
    None => None
  }
  let service_tier = match json.get("service_tier") {
    Some(Null) => None
    Some(service_tier) => {
      let service_tier : ChatCompletionServiceTier = @json.from_json(
        service_tier,
        path=json_path.add_key("service_tier"),
      )
      Some(service_tier)
    }
    None => None
  }
  ChatCompletion::{
    id,
    choices,
    created: created.to_int(),
    model,
    usage,
    system_fingerprint,
    service_tier,
  }
}

///|
pub enum ChatCompletionContentPartParam {
  Text(ChatCompletionContentPartTextParam)
}

///|
pub impl ToJson for ChatCompletionContentPartParam with to_json(
  self : ChatCompletionContentPartParam,
) -> Json {
  match self {
    Text(param) => param.to_json()
  }
}

///|
pub fn text_content_part(
  text : String,
  cache_control? : CacheControl,
) -> ChatCompletionContentPartParam {
  ChatCompletionContentPartParam::Text({ text, cache_control })
}

///|
pub(all) enum CacheControl {
  Ephemeral
}

///|
pub impl ToJson for CacheControl with to_json(self : CacheControl) -> Json {
  match self {
    Ephemeral => { "type": "ephemeral" }
  }
}

///|
pub(all) struct ChatCompletionContentPartTextParam {
  text : String
  cache_control : CacheControl?
}

///|
pub impl ToJson for ChatCompletionContentPartTextParam with to_json(
  self : ChatCompletionContentPartTextParam,
) -> Json {
  let json : Map[String, Json] = { "type": "text", "text": self.text.to_json() }
  if self.cache_control is Some(cache_control) {
    json["cache_control"] = cache_control.to_json()
  }
  Json::object(json)
}

///|
pub struct ChatCompletionSystemMessageParam {
  content : Array[ChatCompletionContentPartParam]
  name : String?
}

///|
pub struct ChatCompletionUserMessageParam {
  content : Array[ChatCompletionContentPartParam]
  name : String?
}

///|
typealias ChatCompletionMessageToolCall as ChatCompletionMessageToolCallParam

///|
pub struct ChatCompletionAssistantMessageParam {
  content : Array[ChatCompletionContentPartParam]
  name : String?
  tool_calls : Array[ChatCompletionMessageToolCallParam]
  function_call : ChatCompletionMessageFunctionCall?
}

///|
pub struct ChatCompletionToolMessageParam {
  content : Array[ChatCompletionContentPartParam]
  tool_call_id : String
}

///|
pub enum ChatCompletionMessageParam {
  System(ChatCompletionSystemMessageParam)
  User(ChatCompletionUserMessageParam)
  Assistant(ChatCompletionAssistantMessageParam)
  Tool(ChatCompletionToolMessageParam)
}

///|
pub impl ToJson for ChatCompletionMessageParam with to_json(
  self : ChatCompletionMessageParam,
) {
  fn content_parts_to_json(
    content_parts : Array[ChatCompletionContentPartParam],
    json : Map[String, Json],
  ) -> Unit {
    match content_parts {
      [] => ()
      [Text(text)] if text.cache_control is None =>
        json["content"] = text.text.to_json()
      [.. parts] => json["content"] = parts.to_json()
    }
  }

  match self {
    System(param) => {
      let json : Map[String, Json] = { "role": "system" }
      content_parts_to_json(param.content, json)
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      Json::object(json)
    }
    User(param) => {
      let json : Map[String, Json] = { "role": "user" }
      content_parts_to_json(param.content, json)
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      Json::object(json)
    }
    Assistant(param) => {
      let json : Map[String, Json] = {
        "role": "assistant",
        "tool_calls": param.tool_calls.to_json(),
      }
      content_parts_to_json(param.content, json)
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      if param.function_call is Some(function_call) {
        json["function_call"] = function_call.to_json()
      }
      Json::object(json)
    }
    Tool(param) =>
      {
        "role": "tool",
        "content": param.content,
        "tool_call_id": param.tool_call_id,
      }
  }
}

///|
trait ToChatCompletionMessageParamContent {
  to_chat_completion_message_param_content(self : Self) -> Array[
    ChatCompletionContentPartParam,
  ]
}

///|
pub impl ToChatCompletionMessageParamContent for String with to_chat_completion_message_param_content(
  self : String,
) -> Array[ChatCompletionContentPartParam] {
  [text_content_part(self)]
}

///|
pub impl ToChatCompletionMessageParamContent for Array[
  ChatCompletionContentPartParam,
] with to_chat_completion_message_param_content(
  self : Array[ChatCompletionContentPartParam],
) -> Array[ChatCompletionContentPartParam] {
  self
}

///|
pub fn[T : ToChatCompletionMessageParamContent] system_message(
  content~ : T,
  name? : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::System({
    content: content.to_chat_completion_message_param_content(),
    name,
  })
}

///|
pub fn[T : ToChatCompletionMessageParamContent] user_message(
  content~ : T,
  name? : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::User({
    content: content.to_chat_completion_message_param_content(),
    name,
  })
}

///|
pub fn[T : ToChatCompletionMessageParamContent] tool_message(
  content~ : T,
  tool_call_id~ : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::Tool({
    content: content.to_chat_completion_message_param_content(),
    tool_call_id,
  })
}

///|
pub struct FunctionDefinition {
  name : String
  description : String
  parameters : Map[String, Json]
  strict : Bool?
}

///|
impl ToJson for FunctionDefinition with to_json(self : FunctionDefinition) -> Json {
  let json : Map[String, Json] = {
    "name": Json::string(self.name),
    "description": Json::string(self.description),
    "parameters": Json::object(self.parameters),
  }
  if self.strict is Some(bool) {
    json["strict"] = Json::boolean(bool)
  }
  Json::object(json)
}

///|
pub fn tool(
  name~ : String,
  description~ : String,
  parameters~ : Map[String, Json],
  strict? : Bool,
) -> ChatCompletionToolParam {
  Function(FunctionDefinition::{ name, description, parameters, strict })
}

///|
pub enum ChatCompletionToolParam {
  Function(FunctionDefinition)
}

///|
pub impl ToJson for ChatCompletionToolParam with to_json(
  self : ChatCompletionToolParam,
) -> Json {
  match self {
    Function(function_definition) =>
      { "type": "function", "function": function_definition.to_json() }
  }
}

///|
pub struct ChatCompletionChunkChoiceDeltaToolCallFunction {
  arguments : String?
  name : String?
}

///|
impl @json.FromJson for ChatCompletionChunkChoiceDeltaToolCallFunction with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoiceDeltaToolCallFunction {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let arguments = match json.get("arguments") {
    None | Some(Null) => None
    Some(String(arguments)) => Some(arguments)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'arguments' to be a string"),
      )
  }
  let name = match json.get("name") {
    None | Some(Null) => None
    Some(String(name)) => Some(name)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'name' to be a string"))
  }
  ChatCompletionChunkChoiceDeltaToolCallFunction::{ arguments, name }
}

///|
pub struct ChatCompletionChunkChoiceDeltaToolCall {
  index : Int
  id : String?
  function : ChatCompletionChunkChoiceDeltaToolCallFunction
}

///|
impl @json.FromJson for ChatCompletionChunkChoiceDeltaToolCall with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoiceDeltaToolCall {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("index") is Some(Number(index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'index' field"))
  }
  let id = match json.get("id") {
    None | Some(Null) => None
    Some(String(id)) => Some(id)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'id' to be a string"))
  }
  guard json.get("function") is Some(function) else {
    raise @json.JsonDecodeError((json_path, "Missing 'function' field"))
  }
  let function : ChatCompletionChunkChoiceDeltaToolCallFunction = @json.from_json(
    function,
    path=json_path.add_key("function"),
  )
  ChatCompletionChunkChoiceDeltaToolCall::{
    index: index.to_int(),
    id,
    function,
  }
}

///|
pub enum ChatCompletionRole {
  Developer
  System
  User
  Assistant
  Tool
}

///|
impl @json.FromJson for ChatCompletionRole with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionRole {
  guard json is String(role) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match role {
    "developer" => ChatCompletionRole::Developer
    "system" => ChatCompletionRole::System
    "user" => ChatCompletionRole::User
    "assistant" => ChatCompletionRole::Assistant
    "tool" => ChatCompletionRole::Tool
    role => raise @json.JsonDecodeError((json_path, "Unknown role: \{role}"))
  }
}

///|
pub struct ChatCompletionChunkChoiceDelta {
  content : String?
  role : ChatCompletionRole?
  tool_calls : Array[ChatCompletionChunkChoiceDeltaToolCall]?
}

///|
impl @json.FromJson for ChatCompletionChunkChoiceDelta with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoiceDelta {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let content = match json.get("content") {
    Some(Null) => None
    Some(content) => {
      let content : String = @json.from_json(
        content,
        path=json_path.add_key("content"),
      )
      Some(content)
    }
    None => None
  }
  let role = match json.get("role") {
    Some(role) => {
      let role : ChatCompletionRole = @json.from_json(
        role,
        path=json_path.add_key("role"),
      )
      Some(role)
    }
    None => None
  }
  let tool_calls = match json.get("tool_calls") {
    Some(tool_calls) => {
      let tool_calls : Array[ChatCompletionChunkChoiceDeltaToolCall] = @json.from_json(
        tool_calls,
        path=json_path.add_key("tool_calls"),
      )
      Some(tool_calls)
    }
    None => None
  }
  ChatCompletionChunkChoiceDelta::{ content, role, tool_calls }
}

///|
pub struct ChatCompletionChunkChoice {
  index : Int
  delta : ChatCompletionChunkChoiceDelta
  finish_reason : ChatCompletionChoiceFinishReason?
}

///|
impl @json.FromJson for ChatCompletionChunkChoice with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunkChoice {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("index") is Some(Number(index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'index' field"))
  }
  guard json.get("delta") is Some(delta) else {
    raise @json.JsonDecodeError((json_path, "Missing 'delta' field"))
  }
  let delta : ChatCompletionChunkChoiceDelta = @json.from_json(
    delta,
    path=json_path.add_key("delta"),
  )
  let finish_reason = match json.get("finish_reason") {
    Some(Null) => None
    Some(finish_reason) => {
      let finish_reason : ChatCompletionChoiceFinishReason = @json.from_json(
        finish_reason,
        path=json_path.add_key("finish_reason"),
      )
      Some(finish_reason)
    }
    None => None
  }
  ChatCompletionChunkChoice::{ index: index.to_int(), delta, finish_reason }
}

///|
pub struct ChatCompletionChunk {
  id : String
  choices : Array[ChatCompletionChunkChoice]
  created : Int
  model : String
  usage : CompletionUsage?
  system_fingerprint : String?
  service_tier : ChatCompletionChunkServiceTier?
}

///|
pub impl @json.FromJson for ChatCompletionChunk with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionChunk {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("id") is Some(String(id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'id' field"))
  }
  guard json.get("choices") is Some(choices) else {
    raise @json.JsonDecodeError((json_path, "Missing 'choices' field"))
  }
  let choices : Array[ChatCompletionChunkChoice] = @json.from_json(
    choices,
    path=json_path.add_key("choices"),
  )
  guard json.get("created") is Some(Number(created, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'created' field"))
  }
  guard json.get("model") is Some(String(model)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'model' field"))
  }
  let usage = match json.get("usage") {
    Some(Null) => None
    Some(usage) => {
      let usage : CompletionUsage = @json.from_json(
        usage,
        path=json_path.add_key("usage"),
      )
      Some(usage)
    }
    None => None
  }
  let system_fingerprint = match json.get("system_fingerprint") {
    Some(Null) => None
    Some(String(fingerprint)) => Some(fingerprint)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'system_fingerprint' to be a string"),
      )
    None => None
  }
  let service_tier = match json.get("service_tier") {
    Some(Null) => None
    Some(service_tier) => {
      let service_tier : ChatCompletionChunkServiceTier = @json.from_json(
        service_tier,
        path=json_path.add_key("service_tier"),
      )
      Some(service_tier)
    }
    None => None
  }
  ChatCompletionChunk::{
    id,
    choices,
    created: created.to_int(),
    model,
    usage,
    system_fingerprint,
    service_tier,
  }
}

///|
pub fn[T : ToChatCompletionMessageParamContent] assistant_message(
  content? : T,
  tool_calls? : Array[ChatCompletionMessageToolCall] = [],
  name? : String,
) -> ChatCompletionMessageParam {
  let content = match content {
    Some(content) => content.to_chat_completion_message_param_content()
    None => []
  }
  ChatCompletionMessageParam::Assistant(ChatCompletionAssistantMessageParam::{
    content,
    name,
    tool_calls,
    function_call: None,
  })
}
