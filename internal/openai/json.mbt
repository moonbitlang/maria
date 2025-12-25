///|
/// Create a usage tracking parameter for chat completions.
///
/// Controls whether token usage information is included in the response.
///
/// Parameters:
/// - include_: Whether to include usage statistics in the response
///
/// Returns a CompletionUsageParam that can be passed to chat_completion.
pub fn usage(include_~ : Bool) -> CompletionUsageParam {
  CompletionUsageParam::{ include_, }
}

///|
pub fn stream_options(
  include_obfuscation? : Bool,
  include_usage? : Bool,
) -> ChatCompletionStreamOptionsParam {
  ChatCompletionStreamOptionsParam::{ include_obfuscation, include_usage }
}

///|
/// Create a chat completion parameter object.
///
/// This function constructs a complete set of parameters for a chat completion
/// request, including messages, tools, and various configuration options.
///
/// Parameters
///
/// - `model`: The model identifier (e.g., "gpt-4o-mini", "gpt-4-turbo")
/// - `messages`: Array of messages forming the conversation history
/// - `tools`: Optional array of function tools the model can call
/// - `usage`: Optional parameter to request usage statistics
/// - `user`: Optional unique identifier for the end-user
/// - `max_tokens`: Optional maximum number of tokens to generate
/// - `temperature`: Optional sampling temperature (0.0 to 2.0)
/// - `response_format`: Optional format for structured responses
///
/// Returns a ChatCompletionParam object ready to be passed to the chat function.
pub fn chat_completion(
  model~ : String,
  messages~ : Array[ChatCompletionMessageParam],
  tools? : Array[ChatCompletionToolParam] = [],
  usage? : CompletionUsageParam,
  user? : String,
  max_tokens? : Int,
  temperature? : Double,
  response_format? : ResponseFormat,
  stream? : Bool,
  stream_options? : ChatCompletionStreamOptionsParam,
  tool_choice? : ChatCompletionToolChoice,
) -> Request {
  Request::{
    model,
    messages,
    tools,
    usage,
    user,
    max_tokens,
    temperature,
    response_format,
    stream,
    stream_options,
    tool_choice,
  }
}

///|
/// Create a text content part for message content.
///
/// Text content parts are the building blocks of message content in chat completions.
/// They can optionally include cache control directives for prompt caching.
///
/// Parameters
/// - `text`: The text content
/// - `cache_control`: Optional cache control directive (currently only `Ephemeral` is supported)
///
/// Returns a `ChatCompletionContentPartParam` that can be included in message content
pub fn text_content_part(
  text : String,
  cache_control? : CacheControl,
) -> ChatCompletionContentPartParam {
  ChatCompletionContentPartParam::Text({ text, cache_control })
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
pub impl ToChatCompletionMessageParamContent for StringView with to_chat_completion_message_param_content(
  self : StringView,
) -> Array[ChatCompletionContentPartParam] {
  [text_content_part(self.to_string())]
}

///|
pub impl ToChatCompletionMessageParamContent for ChatCompletionContentPartParam with to_chat_completion_message_param_content(
  self : ChatCompletionContentPartParam,
) -> Array[ChatCompletionContentPartParam] {
  [self]
}

///|
pub impl[T : ToChatCompletionMessageParamContent] ToChatCompletionMessageParamContent for Array[
  T,
] with to_chat_completion_message_param_content(self : Array[T]) -> Array[
  ChatCompletionContentPartParam,
] {
  let parts = []
  for part in self {
    parts.append(part.to_chat_completion_message_param_content())
  }
  parts
}

///|
/// Create a system message for chat completion.
///
/// System messages set the behavior and context for the assistant. They are
/// typically placed at the beginning of the conversation.
///
/// Parameters
///
/// - `content`: The system message content
/// - `name`: Optional name to identify the message author
///
/// Returns a ChatCompletionMessageParam with role "system".
pub fn[T : ToChatCompletionMessageParamContent] system_message(
  content~ : T,
  name? : String,
) -> ChatCompletionMessageParam {
  System({ content: content.to_chat_completion_message_param_content(), name })
}

///|
/// Create a user message for chat completion.
///
/// User messages represent input from the end user in the conversation.
///
/// Parameters
///
/// - `content`: The user message content
/// - `name`: Optional name to identify the user
///
/// Returns a ChatCompletionMessageParam representing the user's input with role "user".
pub fn[T : ToChatCompletionMessageParamContent] user_message(
  content~ : T,
  name? : String,
) -> ChatCompletionMessageParam {
  User({ content: content.to_chat_completion_message_param_content(), name })
}

///|
/// Create a tool result message for chat completion.
///
/// Tool messages contain the results of function tool calls made by the assistant.
/// They must reference a specific tool call ID from a previous assistant message.
///
/// Parameters
///
/// - `content`: The tool execution result
/// - `tool_call_id`: The ID of the tool call this result corresponds to
///
/// Returns a ChatCompletionMessageParam with role "tool".
pub fn[T : ToChatCompletionMessageParamContent] tool_message(
  content~ : T,
  tool_call_id~ : String,
) -> ChatCompletionMessageParam {
  Tool({
    content: content.to_chat_completion_message_param_content(),
    tool_call_id,
  })
}

///|
/// Create a function tool definition for chat completion.
///
/// Tools allow the model to call functions to perform actions or retrieve
/// information. The model will decide when and how to call these functions
/// based on the conversation context.
///
/// Parameters
///
/// - `name`: The name of the function tool
/// - `description`: A description of what the function does (helps the model decide when to call it)
/// - `parameters`: JSON schema describing the function's parameters
/// - `strict`: Optional flag to enable strict schema validation
///
/// Returns a ChatCompletionToolParam representing the function tool.
pub fn tool(
  name~ : String,
  description~ : String,
  parameters~ : Json,
  strict? : Bool,
) -> ChatCompletionToolParam {
  Function(FunctionDefinition::{ name, description, parameters, strict })
}

///|
/// Create an assistant message for chat completion.
///
/// Assistant messages represent responses from the AI model. They can contain
/// text content and/or tool call requests. This function is useful when
/// constructing multi-turn conversations or when replaying conversation history.
///
/// Parameters
/// - `content`: Optional content from the assistant
/// - `tool_calls`: Optional array of tool calls the assistant made
/// - `name`: Optional name to identify the assistant
///
/// Returns a ChatCompletionMessageParam with role "assistant".
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
  })
}

///|
/// Create a JSON schema response format.
///
/// This function creates a response format that constrains the model to generate
/// JSON output conforming to a specific schema. The model will automatically
/// structure its response to match the provided schema.
///
/// Parameters
/// - `name`: A name for the schema (used for identification)
/// - `schema`: JSON schema object defining the expected structure
/// - `description`: Optional description of the schema's purpose
/// - `strict`: Optional flag to enable strict schema validation
///
/// Returns a ResponseFormat that can be used in chat completion requests.
pub fn json_schema(
  name~ : String,
  schema~ : Map[String, Json],
  description? : String,
  strict? : Bool,
) -> ResponseFormat {
  JsonSchema(JsonSchema::{ name, description, schema, strict })
}

///|
pub fn tool_call(
  id~ : String,
  name~ : String,
  arguments? : String,
) -> ChatCompletionMessageToolCall {
  ChatCompletionMessageToolCall::{
    id,
    function: ChatCompletionMessageToolCallFunction::{ name, arguments },
  }
}

///|
pub fn chunk(
  id~ : String,
  choices~ : Array[ChatCompletionChunkChoice],
  created~ : Int,
  model~ : String,
  usage? : CompletionUsage,
  system_fingerprint? : String,
  service_tier? : ChatCompletionChunkServiceTier,
  error? : OpenRouterErrorResponse,
) -> ChatCompletionChunk {
  ChatCompletionChunk::{
    id,
    choices,
    created,
    model,
    usage,
    system_fingerprint,
    service_tier,
    error,
  }
}

///|
pub fn chunk_choice_delta_tool_call_function(
  arguments? : String,
  name? : String,
) -> ChatCompletionChunkChoiceDeltaToolCallFunction {
  ChatCompletionChunkChoiceDeltaToolCallFunction::{ arguments, name }
}

///|
pub fn chunk_choice_delta_tool_call(
  index~ : Int,
  id? : String,
  function~ : ChatCompletionChunkChoiceDeltaToolCallFunction,
) -> ChatCompletionChunkChoiceDeltaToolCall {
  ChatCompletionChunkChoiceDeltaToolCall::{ index, id, function }
}

///|
pub fn chunk_choice_delta(
  content? : String,
  refusal? : String,
  role? : ChatCompletionRole,
  tool_calls? : Array[ChatCompletionChunkChoiceDeltaToolCall],
) -> ChatCompletionChunkChoiceDelta {
  ChatCompletionChunkChoiceDelta::{ content, refusal, role, tool_calls }
}

///|
pub fn chunk_choice(
  index~ : Int,
  delta~ : ChatCompletionChunkChoiceDelta,
  finish_reason? : ChatCompletionChoiceFinishReason,
) -> ChatCompletionChunkChoice {
  ChatCompletionChunkChoice::{ index, delta, finish_reason }
}
