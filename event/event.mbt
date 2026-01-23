///|
/// Event type that occurs during agent conversation lifecycle.
///
/// A typical conversation lifecycle looks like this:
///
/// ```moonbit no-check
/// // add system and user messages
/// UserMessage (system)
/// UserMessage (user)
/// // calling agent.start()
/// PreConversation
/// while true {
///   // poll external events
///   ExternalEventReceived (if any)
///   // count tokens before request
///   TokenCounted
///   // prune context if necessary
///   ContextPruned
///   // receive assistant response
///   AssistantMessage
///   // executing tool call
///   PreToolCall
///   PostToolCall
///   UserMessage (tool)
///   // continue to iterate if there are more messages
/// }
/// // conversation ended
/// PostConversation
/// ```
pub struct Event {
  id : @uuid.Uuid
  created : @clock.Timestamp
  desc : EventDesc
} derive(Eq, Show)

///|
/// Creates a new `Event` with the specified parameters.
///
/// Parameters:
///
/// * `id` : The unique identifier for the event.
/// * `created` : The timestamp when the event was created. Defaults to the
///   current time if not provided.
/// * `desc` : The event description that specifies the type and content of the
///   event.
///
/// Returns a new `Event` instance.
pub fn Event::new(
  id~ : @uuid.Uuid,
  created? : @clock.Timestamp = @clock.epoch.now(),
  desc : EventDesc,
) -> Event {
  Event::{ id, created, desc }
}

///|
pub(all) enum EventDesc {
  /// Event triggered when a model is loaded.
  ModelLoaded(name~ : String)
  /// Event triggered before a conversation starts.
  PreConversation
  /// Event triggered after a conversation ends.
  PostConversation
  /// Event triggered when the system prompt is being set.
  SystemPromptSet(String?)
  /// Event triggered when a message is unqueued from the pending queue.
  MessageUnqueued(id~ : @uuid.Uuid)
  /// Event triggered when a message is queued to be sent to the model.
  /// The message ID can be obtained via the return value of `queue_message`
  /// function.
  MessageQueued(id~ : @uuid.Uuid)
  /// Event triggered when a tool is added to the agent. This message will only
  /// be triggered once per agent instance.
  ToolAdded(@tool.ToolDesc)
  /// Event triggered before a tool is called.
  PreToolCall(@ai.ToolCall)
  /// Event triggered after a tool call is completed.
  ///
  /// If you are interested in the result of the tool call, then this is the
  /// event you might want to listen for.
  ///
  /// The `result` field can be used to determine whether the tool call was
  /// successful or not. `rendered` field is the string representation of the
  /// tool call result, which can be used for both human and LLM consumption.
  PostToolCall(@ai.ToolCall, result~ : Result[Json, Json], rendered~ : String)
  /// Event triggered when tokens are counted for a message or tool call.
  /// Tokens are counted in following scenarios:
  ///
  /// 1. Before a request is being sent, tokens are counted for all messages
  ///    in the conversation history to decide if to perform context pruning.
  /// 2. The context pruning algorithm may count token for multiple times to
  ///    determine when to stop.
  ///
  /// FIXME: Currently this event is triggered multiple times in a row.
  TokenCounted(Int)
  /// Event triggered when context pruning is performed.
  ///
  /// FIXME: Currently this event is triggered even if the context is with-in
  /// the limit and no pruning is performed.
  ContextPruned(origin_token_count~ : Int, pruned_token_count~ : Int)
  /// Event triggered when a assistant message is received from the model.
  AssistantMessage(
    usage~ : @ai.Usage?,
    tool_calls~ : Array[@ai.ToolCall],
    String
  )
  /// Diagnostics from IDE (errors, warnings from the problems panel)
  Diagnostics(@diagnostics.Diagnostics)
  /// User sends an immediate message (interrupting current flow)
  UserMessage(String)
  /// Cancelled
  Cancelled
  /// Failed. We cannot use `Error` here because it is impossible to deserialize
  /// `Error` from JSON.
  Failed(Json)
} derive(Eq, Show)

///|
pub impl ToJson for EventDesc with to_json(self : EventDesc) -> Json {
  match self {
    ModelLoaded(name~) => { "msg": "ModelLoaded", "name": name.to_json() }
    TokenCounted(token_count) =>
      { "msg": "TokenCounted", "token_count": token_count }
    ContextPruned(origin_token_count~, pruned_token_count~) =>
      {
        "msg": "ContextPruned",
        "origin_token_count": origin_token_count,
        "pruned_token_count": pruned_token_count,
      }
    PreToolCall(tool_call) => {
      let tool_call = tool_call.to_openai()
      match tool_call.function.arguments {
        None =>
          {
            "msg": "PreToolCall",
            "tool_call": tool_call,
            "name": tool_call.function.name,
          }
        Some(arguments) =>
          try @json.parse(arguments) catch {
            error =>
              {
                "msg": "PreToolCall",
                "tool_call": tool_call,
                "name": tool_call.function.name,
                "args": tool_call.function.arguments,
                "error": error,
              }
          } noraise {
            args =>
              {
                "msg": "PreToolCall",
                "tool_call": tool_call,
                "name": tool_call.function.name,
                "args": args,
              }
          }
      }
    }
    PostToolCall(tool_call, result~, rendered~) => {
      let tool_call = tool_call.to_openai()
      match result {
        Ok(output) =>
          {
            "msg": "PostToolCall",
            "tool_call": tool_call,
            "name": tool_call.function.name,
            "result": output,
            "text": rendered,
          }
        Err(error) =>
          {
            "msg": "PostToolCall",
            "tool_call": tool_call,
            "name": tool_call.function.name,
            "error": error,
            "text": rendered,
          }
      }
    }
    PreConversation => { "msg": "PreConversation" }
    PostConversation => { "msg": "PostConversation" }
    SystemPromptSet(Some(prompt)) =>
      { "msg": "SystemPromptSet", "prompt": prompt }
    SystemPromptSet(None) => { "msg": "SystemPromptSet" }
    MessageQueued(id~) => { "msg": "MessageQueued", "message": { "id": id } }
    MessageUnqueued(id~) =>
      { "msg": "MessageUnqueued", "message": { "id": id } }
    ToolAdded(tool_desc) =>
      {
        "msg": "ToolAdded",
        "tool": {
          "name": tool_desc.name,
          "description": tool_desc.description,
          "schema": tool_desc.schema,
        },
      }
    AssistantMessage(usage~, tool_calls~, content) => {
      let json : Map[String, Json] = {
        "msg": "AssistantMessage",
        "tool_calls": tool_calls.map(fn(tc) { tc.to_openai() }),
        "content": content,
      }
      if usage is Some(usage) {
        json["usage"] = usage.to_openai().to_json()
      }
      Json::object(json)
    }
    Diagnostics(diagnostics) =>
      { "msg": "Diagnostics", "diagnostics": diagnostics.to_json() }
    Cancelled => { "msg": "Cancelled" }
    UserMessage(content) => { "msg": "UserMessage", "content": content }
    Failed(error) => { "msg": "Failed", "error": error }
  }
}

///|
pub impl @json.FromJson for EventDesc with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> EventDesc raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path=json_path)
  let msg : String = object.required("msg", path=json_path)
  match msg {
    "ModelLoaded" => {
      let name : String = object.required("name", path=json_path)
      ModelLoaded(name~)
    }
    "TokenCounted" => {
      let token_count : Int = object.required("token_count", path=json_path)
      TokenCounted(token_count)
    }
    "ContextPruned" => {
      let origin_token_count : Int = object.required(
        "origin_token_count",
        path=json_path,
      )
      let pruned_token_count : Int = object.required(
        "pruned_token_count",
        path=json_path,
      )
      ContextPruned(origin_token_count~, pruned_token_count~)
    }
    "PreToolCall" => {
      let tool_call : @openai.ChatCompletionMessageToolCall = object.required(
        "tool_call",
        path=json_path,
      )
      PreToolCall(@ai.ToolCall::from_openai_tool_call(tool_call))
    }
    "PostToolCall" => {
      let tool_call : @openai.ChatCompletionMessageToolCall = object.required(
        "tool_call",
        path=json_path,
      )
      let result : Result[Json, Json] = match
        (object.get("result"), object.get("error")) {
        (Some(result_json), _) => Ok(result_json)
        (None, Some(error_json)) => Err(error_json)
        (None, None) =>
          raise @json.JsonDecodeError(
            (
              json_path, "PostToolCall event missing both 'result' and 'error' fields",
            ),
          )
      }
      let rendered : String = object.required("text", path=json_path)
      PostToolCall(
        @ai.ToolCall::from_openai_tool_call(tool_call),
        result~,
        rendered~,
      )
    }
    "PreConversation" => PreConversation
    "PostConversation" => PostConversation
    "SystemPromptSet" => {
      let prompt : String? = object.optional("prompt", path=json_path)
      SystemPromptSet(prompt)
    }
    "MessageQueued" => {
      let message_json : Json = object.required("message", path=json_path)
      let message_object = @jsonx.as_object(
        message_json,
        path=json_path.add_key("message"),
      )
      let id : @uuid.Uuid = message_object.required(
        "id",
        path=json_path.add_key("message"),
      )
      MessageQueued(id~)
    }
    "MessageUnqueued" => {
      let message_json : Json = object.required("message", path=json_path)
      let message_object = @jsonx.as_object(
        message_json,
        path=json_path.add_key("message"),
      )
      let id : @uuid.Uuid = message_object.required(
        "id",
        path=json_path.add_key("message"),
      )
      MessageUnqueued(id~)
    }
    "ToolAdded" => {
      let tool_json : Json = object.required("tool", path=json_path)
      let tool_object = @jsonx.as_object(
        tool_json,
        path=json_path.add_key("tool"),
      )
      let name : String = tool_object.required(
        "name",
        path=json_path.add_key("tool"),
      )
      let description : String = tool_object.required(
        "description",
        path=json_path.add_key("tool"),
      )
      let schema : Json = tool_object.required(
        "schema",
        path=json_path.add_key("tool"),
      )
      ToolAdded(@tool.tool_desc(description~, name~, schema~))
    }
    "AssistantMessage" => {
      let usage : @ai.Usage? = match object.get("usage") {
        None | Some(Null) => None
        Some(usage_json) =>
          Some(
            @ai.Usage::from_openai(
              @json.from_json(usage_json, path=json_path.add_key("usage")),
            ),
          )
      }
      let tool_calls : Array[@ai.ToolCall] = match object.get("tool_calls") {
        None => []
        Some(tool_calls_json) => {
          let tcs : Array[@openai.ChatCompletionMessageToolCall] = @json.from_json(
            tool_calls_json,
            path=json_path.add_key("tool_calls"),
          )
          tcs.map(@ai.ToolCall::from_openai_tool_call)
        }
      }
      let content : String = object.required("content", path=json_path)
      AssistantMessage(usage~, tool_calls~, content)
    }
    "Diagnostics" => {
      let diagnostics : @diagnostics.Diagnostics = object.required(
        "diagnostics",
        path=json_path,
      )
      Diagnostics(diagnostics)
    }
    "Cancelled" => Cancelled
    "UserMessage" => {
      let content : String = object.required("content", path=json_path)
      UserMessage(content)
    }
    "Failed" => {
      let error : Json = object.required("error", path=json_path)
      Failed(error)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown 'msg' value in EventDesc: \{msg}"),
      )
  }
}

///|
/// Serializes an `Event` to JSON.
///
/// Note: this implementation behaves identically to the derived version.
/// We manually implement it here to ensure the stability of the JSON format.
pub impl ToJson for Event with to_json(self : Event) -> Json {
  { "id": self.id.to_json(), "created": self.created, "desc": self.desc }
}

///|
/// Deserializes an `Event` from JSON.
///
/// Note: this implementation behaves identically to the derived version.
/// We manually implement it here to ensure the stability of the JSON format.
pub impl @json.FromJson for Event with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Event raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path=json_path)
  let id : @uuid.Uuid = object.required("id", path=json_path)
  let created : @clock.Timestamp = object
    .optional("created", path=json_path)
    .unwrap_or_else(() => @clock.Timestamp::from_ms(0))
  let desc : EventDesc = object.required("desc", path=json_path)
  { id, created, desc }
}

///|
/// External events that can be sent to the agent from outside sources.
/// These events are collected via polling and can influence the conversation.
pub fn Event::is_incoming(self : Event) -> Bool {
  match self.desc {
    Cancelled | UserMessage(_) | Diagnostics(_) => true
    _ => false
  }
}

///|
/// Indicates whether the event signifies the end of a conversation.
pub fn Event::is_stopping(self : Event) -> Bool {
  match self.desc {
    PostConversation | Failed(_) => true
    _ => false
  }
}

///|
/// Indicates whether the event signifies the start of a conversation.
pub fn Event::is_starting(self : Event) -> Bool {
  match self.desc {
    PreConversation => true
    _ => false
  }
}

///|
/// Indicates whether the event represents a cancellation.
pub fn Event::is_cancellation(self : Event) -> Bool {
  match self.desc {
    Cancelled => true
    _ => false
  }
}
