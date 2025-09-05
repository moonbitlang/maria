///|
/// Service tier types for chat completion requests
pub enum ChatCompletionServiceTier {
  Auto
  Default
  Flex
  Scale
  Priority
} derive(Show)

///|
impl ToJson for ChatCompletionServiceTier with to_json(
  self : ChatCompletionServiceTier,
) -> Json {
  match self {
    Auto => Json::string("auto")
    Default => Json::string("default")
    Flex => Json::string("flex")
    Scale => Json::string("scale")
    Priority => Json::string("priority")
  }
}

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
/// Alias for chunk service tier
typealias ChatCompletionServiceTier as ChatCompletionChunkServiceTier

///|
/// Logprobs information for chat completion choices
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
/// Audio information for chat completions
pub struct ChatCompletionAudio {
  id : String?
} derive(Show)

///|
impl @json.FromJson for ChatCompletionAudio with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionAudio {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  let id = match json.get("id") {
    Some(Null) => None
    Some(String(id)) => Some(id)
    Some(_) =>
      raise @json.JsonDecodeError((json_path, "Expected 'id' to be a string"))
    None => None
  }
  ChatCompletionAudio::{ id, }
}

///|
impl ToJson for ChatCompletionAudio with to_json(self : ChatCompletionAudio) -> Json {
  let json : Map[String, Json] = {}
  if self.id is Some(id) {
    json["id"] = Json::string(id)
  }
  Json::object(json)
}

///|
/// Message annotation for web search results
pub struct ChatCompletionMessageAnnotation {
  type_ : String
  text : String
  file_citation : ChatCompletionMessageAnnotationFileCitation?
  file_path : ChatCompletionMessageAnnotationFilePath?
  start_index : Int
  end_index : Int
} derive(Show)

///|
impl @json.FromJson for ChatCompletionMessageAnnotation with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageAnnotation {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("type") is Some(String(type_)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'type' field"))
  }
  guard json.get("text") is Some(String(text)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'text' field"))
  }
  let file_citation = match json.get("file_citation") {
    Some(Null) => None
    Some(file_citation) => {
      let file_citation : ChatCompletionMessageAnnotationFileCitation = @json.from_json(
        file_citation,
        path=json_path.add_key("file_citation"),
      )
      Some(file_citation)
    }
    None => None
  }
  let file_path = match json.get("file_path") {
    Some(Null) => None
    Some(file_path) => {
      let file_path : ChatCompletionMessageAnnotationFilePath = @json.from_json(
        file_path,
        path=json_path.add_key("file_path"),
      )
      Some(file_path)
    }
    None => None
  }
  guard json.get("start_index") is Some(Number(start_index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'start_index' field"))
  }
  guard json.get("end_index") is Some(Number(end_index, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'end_index' field"))
  }
  ChatCompletionMessageAnnotation::{
    type_,
    text,
    file_citation,
    file_path,
    start_index: start_index.to_int(),
    end_index: end_index.to_int(),
  }
}

///|
/// File citation annotation
pub struct ChatCompletionMessageAnnotationFileCitation {
  file_id : String
  quote : String
} derive(Show)

///|
impl @json.FromJson for ChatCompletionMessageAnnotationFileCitation with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageAnnotationFileCitation {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("file_id") is Some(String(file_id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'file_id' field"))
  }
  guard json.get("quote") is Some(String(quote)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'quote' field"))
  }
  ChatCompletionMessageAnnotationFileCitation::{ file_id, quote }
}

///|
/// File path annotation
pub struct ChatCompletionMessageAnnotationFilePath {
  file_id : String
} derive(Show)

///|
impl @json.FromJson for ChatCompletionMessageAnnotationFilePath with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionMessageAnnotationFilePath {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("file_id") is Some(String(file_id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'file_id' field"))
  }
  ChatCompletionMessageAnnotationFilePath::{ file_id, }
}

///|
/// Metadata type alias for key-value pairs
typealias Map[String, String] as Metadata

///|
/// Reasoning effort levels for reasoning models
pub enum ReasoningEffort {
  Minimal
  Low
  Medium
  High
}

///|
impl ToJson for ReasoningEffort with to_json(self : ReasoningEffort) -> Json {
  match self {
    Minimal => Json::string("minimal")
    Low => Json::string("low")
    Medium => Json::string("medium")
    High => Json::string("high")
  }
}

///|
impl @json.FromJson for ReasoningEffort with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ReasoningEffort {
  guard json is String(effort) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match effort {
    "minimal" => ReasoningEffort::Minimal
    "low" => ReasoningEffort::Low
    "medium" => ReasoningEffort::Medium
    "high" => ReasoningEffort::High
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown reasoning effort: \{effort}"),
      )
  }
}

///|
/// Verbosity levels for model responses
pub enum Verbosity {
  Low
  Medium
  High
}

///|
impl ToJson for Verbosity with to_json(self : Verbosity) -> Json {
  match self {
    Low => Json::string("low")
    Medium => Json::string("medium")
    High => Json::string("high")
  }
}

///|
impl @json.FromJson for Verbosity with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Verbosity {
  guard json is String(verbosity) else {
    raise @json.JsonDecodeError((json_path, "Expected a string"))
  }
  match verbosity {
    "low" => Verbosity::Low
    "medium" => Verbosity::Medium
    "high" => Verbosity::High
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown verbosity: \{verbosity}"),
      )
  }
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
  annotations : Array[ChatCompletionMessageAnnotation]
  audio : ChatCompletionAudio?
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
  Assistant({
    content: self.content,
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
  let annotations = match json.get("annotations") {
    Some(annotations) => {
      let annotations : Array[ChatCompletionMessageAnnotation] = @json.from_json(
        annotations,
        path=json_path.add_key("annotations"),
      )
      annotations
    }
    None => []
  }
  let audio = match json.get("audio") {
    Some(Null) => None
    Some(audio) => {
      let audio : ChatCompletionAudio = @json.from_json(
        audio,
        path=json_path.add_key("audio"),
      )
      Some(audio)
    }
    None => None
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
  ChatCompletionMessage::{
    content,
    refusal,
    tool_calls,
    annotations,
    audio,
    function_call,
  }
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
/// Content part types for multimodal messages
pub enum ChatCompletionContentPart {
  Text(ChatCompletionContentPartText)
  ImageURL(ChatCompletionContentPartImage)
  InputAudio(ChatCompletionContentPartInputAudio)
  File(ChatCompletionContentPartFile)
}

///|
impl ToJson for ChatCompletionContentPart with to_json(
  self : ChatCompletionContentPart,
) -> Json {
  match self {
    Text(text) => {
      let json : Map[String, Json] = {
        "type": "text",
        "text": Json::string(text.text),
      }
      Json::object(json)
    }
    ImageURL(image) => {
      let json : Map[String, Json] = {
        "type": "image_url",
        "image_url": image.image_url.to_json(),
      }
      Json::object(json)
    }
    InputAudio(audio) => {
      let json : Map[String, Json] = {
        "type": "input_audio",
        "input_audio": audio.input_audio.to_json(),
      }
      Json::object(json)
    }
    File(file) => {
      let json : Map[String, Json] = {
        "type": "file",
        "file": file.file.to_json(),
      }
      Json::object(json)
    }
  }
}

///|
impl @json.FromJson for ChatCompletionContentPart with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPart {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard obj.get("type") is Some(String(type_)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'type' field"))
  }
  match type_ {
    "text" => {
      let text : ChatCompletionContentPartText = @json.from_json(
        json,
        path=json_path,
      )
      ChatCompletionContentPart::Text(text)
    }
    "image_url" => {
      let image : ChatCompletionContentPartImage = @json.from_json(
        json,
        path=json_path,
      )
      ChatCompletionContentPart::ImageURL(image)
    }
    "input_audio" => {
      let audio : ChatCompletionContentPartInputAudio = @json.from_json(
        json,
        path=json_path,
      )
      ChatCompletionContentPart::InputAudio(audio)
    }
    "file" => {
      let file : ChatCompletionContentPartFile = @json.from_json(
        json,
        path=json_path,
      )
      ChatCompletionContentPart::File(file)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown content part type: \{type_}"),
      )
  }
}

///|
/// Text content part
pub struct ChatCompletionContentPartText {
  text : String
}

///|
impl @json.FromJson for ChatCompletionContentPartText with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartText {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("text") is Some(String(text)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'text' field"))
  }
  ChatCompletionContentPartText::{ text, }
}

///|
/// Image URL content part
pub struct ChatCompletionContentPartImage {
  image_url : ChatCompletionContentPartImageImageURL
}

///|
impl @json.FromJson for ChatCompletionContentPartImage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartImage {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("image_url") is Some(image_url) else {
    raise @json.JsonDecodeError((json_path, "Missing 'image_url' field"))
  }
  let image_url : ChatCompletionContentPartImageImageURL = @json.from_json(
    image_url,
    path=json_path.add_key("image_url"),
  )
  ChatCompletionContentPartImage::{ image_url, }
}

///|
/// Image URL information
pub struct ChatCompletionContentPartImageImageURL {
  url : String
  detail : String?
}

///|
impl ToJson for ChatCompletionContentPartImageImageURL with to_json(
  self : ChatCompletionContentPartImageImageURL,
) -> Json {
  let json : Map[String, Json] = { "url": Json::string(self.url) }
  if self.detail is Some(detail) {
    json["detail"] = Json::string(detail)
  }
  Json::object(json)
}

///|
impl @json.FromJson for ChatCompletionContentPartImageImageURL with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartImageImageURL {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("url") is Some(String(url)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'url' field"))
  }
  let detail = match json.get("detail") {
    Some(Null) => None
    Some(String(detail)) => Some(detail)
    Some(_) =>
      raise @json.JsonDecodeError(
        (json_path, "Expected 'detail' to be a string"),
      )
    None => None
  }
  ChatCompletionContentPartImageImageURL::{ url, detail }
}

///|
/// Input audio content part
pub struct ChatCompletionContentPartInputAudio {
  input_audio : ChatCompletionContentPartInputAudioInputAudio
}

///|
impl @json.FromJson for ChatCompletionContentPartInputAudio with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartInputAudio {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("input_audio") is Some(input_audio) else {
    raise @json.JsonDecodeError((json_path, "Missing 'input_audio' field"))
  }
  let input_audio : ChatCompletionContentPartInputAudioInputAudio = @json.from_json(
    input_audio,
    path=json_path.add_key("input_audio"),
  )
  ChatCompletionContentPartInputAudio::{ input_audio, }
}

///|
/// Input audio information
pub struct ChatCompletionContentPartInputAudioInputAudio {
  data : String
  format : String
}

///|
impl ToJson for ChatCompletionContentPartInputAudioInputAudio with to_json(
  self : ChatCompletionContentPartInputAudioInputAudio,
) -> Json {
  { "data": self.data, "format": self.format }
}

///|
impl @json.FromJson for ChatCompletionContentPartInputAudioInputAudio with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartInputAudioInputAudio {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("data") is Some(String(data)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'data' field"))
  }
  guard json.get("format") is Some(String(format)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'format' field"))
  }
  ChatCompletionContentPartInputAudioInputAudio::{ data, format }
}

///|
/// File content part
pub struct ChatCompletionContentPartFile {
  file : ChatCompletionContentPartFileFile
}

///|
impl @json.FromJson for ChatCompletionContentPartFile with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartFile {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("file") is Some(file) else {
    raise @json.JsonDecodeError((json_path, "Missing 'file' field"))
  }
  let file : ChatCompletionContentPartFileFile = @json.from_json(
    file,
    path=json_path.add_key("file"),
  )
  ChatCompletionContentPartFile::{ file, }
}

///|
/// File information
pub struct ChatCompletionContentPartFileFile {
  file_id : String
}

///|
impl ToJson for ChatCompletionContentPartFileFile with to_json(
  self : ChatCompletionContentPartFileFile,
) -> Json {
  { "file_id": self.file_id }
}

///|
impl @json.FromJson for ChatCompletionContentPartFileFile with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> ChatCompletionContentPartFileFile {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("file_id") is Some(String(file_id)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'file_id' field"))
  }
  ChatCompletionContentPartFileFile::{ file_id, }
}

///|
pub struct CompletionUsage {
  completion_tokens : Int
  prompt_tokens : Int
  total_tokens : Int
} derive(Show)

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
  guard json.get("prompt_tokens") is Some(Number(prompt_tokens, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'prompt_tokens' field"))
  }
  guard json.get("total_tokens") is Some(Number(total_tokens, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'total_tokens' field"))
  }
  CompletionUsage::{
    completion_tokens: completion_tokens.to_int(),
    prompt_tokens: prompt_tokens.to_int(),
    total_tokens: total_tokens.to_int(),
  }
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
pub struct ChatCompletionSystemMessageParam {
  content : String
  name : String?
}

///|
pub struct ChatCompletionUserMessageParam {
  content : String
  name : String?
}

///|
typealias ChatCompletionMessageToolCall as ChatCompletionMessageToolCallParam

///|
pub struct ChatCompletionAssistantMessageParam {
  content : String?
  name : String?
  tool_calls : Array[ChatCompletionMessageToolCallParam]
  function_call : ChatCompletionMessageFunctionCall?
}

///|
pub struct ChatCompletionToolMessageParam {
  content : String
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
  match self {
    System(param) => {
      let json : Map[String, Json] = {
        "role": "system",
        "content": Json::string(param.content),
      }
      if param.name is Some(name) {
        json["name"] = Json::string(name)
      }
      Json::object(json)
    }
    User(param) => {
      let json : Map[String, Json] = {
        "role": "user",
        "content": Json::string(param.content),
      }
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
      if param.content is Some(content) {
        json["content"] = Json::string(content)
      }
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
pub fn system_message(
  content~ : String,
  name? : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::System({ content, name })
}

///|
pub fn user_message(
  content~ : String,
  name? : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::User({ content, name })
}

///|
pub fn tool_message(
  content~ : String,
  tool_call_id~ : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::Tool({ content, tool_call_id })
}

///|
/// Audio parameters for chat completion
pub struct ChatCompletionAudioParam {
  voice : String
  format : String
}

///|
impl ToJson for ChatCompletionAudioParam with to_json(
  self : ChatCompletionAudioParam,
) -> Json {
  { "voice": self.voice, "format": self.format }
}

///|
/// Streaming options for chat completion
pub struct ChatCompletionStreamOptions {
  include_usage : Bool?
}

///|
impl ToJson for ChatCompletionStreamOptions with to_json(
  self : ChatCompletionStreamOptions,
) -> Json {
  let json : Map[String, Json] = {}
  if self.include_usage is Some(include_usage) {
    json["include_usage"] = Json::boolean(include_usage)
  }
  Json::object(json)
}

///|
/// Response format types
pub enum ChatCompletionResponseFormat {
  JsonObject
  JsonSchema(ChatCompletionResponseFormatJsonSchema)
  Text
}

///|
impl ToJson for ChatCompletionResponseFormat with to_json(
  self : ChatCompletionResponseFormat,
) -> Json {
  match self {
    JsonObject => { "type": "json_object" }
    JsonSchema(schema) => {
      let json : Map[String, Json] = {
        "type": "json_schema",
        "json_schema": schema.to_json(),
      }
      Json::object(json)
    }
    Text => { "type": "text" }
  }
}

///|
/// JSON schema for response format
pub struct ChatCompletionResponseFormatJsonSchema {
  name : String
  description : String?
  schema : Map[String, Json]
  strict : Bool?
}

///|
impl ToJson for ChatCompletionResponseFormatJsonSchema with to_json(
  self : ChatCompletionResponseFormatJsonSchema,
) -> Json {
  let json : Map[String, Json] = {
    "name": Json::string(self.name),
    "schema": Json::object(self.schema),
  }
  if self.description is Some(description) {
    json["description"] = Json::string(description)
  }
  if self.strict is Some(strict) {
    json["strict"] = Json::boolean(strict)
  }
  Json::object(json)
}

///|
/// Prediction content for static predicted output
pub struct ChatCompletionPredictionContent {
  type_ : String
  content : String
}

///|
impl ToJson for ChatCompletionPredictionContent with to_json(
  self : ChatCompletionPredictionContent,
) -> Json {
  { "type": self.type_, "content": self.content }
}

///|
/// Stop sequences parameter
pub enum ChatCompletionStopParam {
  String(String)
  Array(Array[String])
}

///|
impl ToJson for ChatCompletionStopParam with to_json(
  self : ChatCompletionStopParam,
) -> Json {
  match self {
    String(s) => Json::string(s)
    Array(arr) => arr.to_json()
  }
}

///|
/// Web search options
pub struct ChatCompletionWebSearchOptions {
  max_results : Int?
}

///|
impl ToJson for ChatCompletionWebSearchOptions with to_json(
  self : ChatCompletionWebSearchOptions,
) -> Json {
  let json : Map[String, Json] = {}
  if self.max_results is Some(max_results) {
    json["max_results"] = max_results.to_json()
  }
  Json::object(json)
}

///|
priv struct FunctionDefinition {
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
enum ChatCompletionToolParam {
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
pub fn text_content_part(text : String) -> ChatCompletionContentPart {
  ChatCompletionContentPart::Text(ChatCompletionContentPartText::{ text, })
}

///|
pub fn image_content_part(
  url : String,
  detail? : String,
) -> ChatCompletionContentPart {
  ChatCompletionContentPart::ImageURL(ChatCompletionContentPartImage::{
    image_url: ChatCompletionContentPartImageImageURL::{ url, detail },
  })
}

///|
pub fn audio_content_part(
  data : String,
  format : String,
) -> ChatCompletionContentPart {
  ChatCompletionContentPart::InputAudio(ChatCompletionContentPartInputAudio::{
    input_audio: ChatCompletionContentPartInputAudioInputAudio::{ data, format },
  })
}

///|
pub fn file_content_part(file_id : String) -> ChatCompletionContentPart {
  ChatCompletionContentPart::File(ChatCompletionContentPartFile::{
    file: ChatCompletionContentPartFileFile::{ file_id, },
  })
}

///|
pub fn assistant_message(
  content? : String,
  tool_calls? : Array[ChatCompletionMessageToolCall] = [],
  name? : String,
) -> ChatCompletionMessageParam {
  ChatCompletionMessageParam::Assistant(ChatCompletionAssistantMessageParam::{
    content,
    name,
    tool_calls,
    function_call: None,
  })
}
