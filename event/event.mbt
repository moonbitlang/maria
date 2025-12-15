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
pub(all) struct Event {
  id : @uuid.Uuid
  desc : EventDesc
} derive(Eq, Show)

///|
pub(all) enum EventDesc {
  /// Event triggered before a conversation starts.
  PreConversation
  /// Event triggered after a conversation ends.
  PostConversation
  /// Event triggered when a message is unqueued from the pending queue.
  MessageUnqueued(id~ : @uuid.Uuid)
  /// Event triggered when a message is queued to be sent to the model.
  /// The message ID can be obtained via the return value of `queue_message`
  /// function.
  MessageQueued(id~ : @uuid.Uuid)
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
    MessageQueued(id~) => { "msg": "MessageQueued", "message": { "id": id } }
    MessageUnqueued(id~) =>
      { "msg": "MessageUnqueued", "message": { "id": id } }
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
  guard json is Object({ "msg": String(msg), .. } as json_object) else {
    raise @json.JsonDecodeError(
      (json_path, "Missing 'msg' field in OutgoingEvent"),
    )
  }
  match msg {
    "TokenCounted" => {
      guard json_object.get("token_count") is Some(token_count_json) else {
        raise @json.JsonDecodeError(
          (json_path, "TokenCounted event missing 'token_count' field"),
        )
      }
      let token_count : Int = @json.from_json(
        token_count_json,
        path=json_path.add_key("token_count"),
      )
      TokenCounted(token_count)
    }
    "ContextPruned" => {
      guard json_object.get("origin_token_count")
        is Some(origin_token_count_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ContextPruned event missing 'origin_token_count' field"),
        )
      }
      let origin_token_count : Int = @json.from_json(
        origin_token_count_json,
        path=json_path.add_key("origin_token_count"),
      )
      guard json_object.get("pruned_token_count")
        is Some(pruned_token_count_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ContextPruned event missing 'pruned_token_count' field"),
        )
      }
      let pruned_token_count : Int = @json.from_json(
        pruned_token_count_json,
        path=json_path.add_key("pruned_token_count"),
      )
      ContextPruned(origin_token_count~, pruned_token_count~)
    }
    "PreToolCall" => {
      guard json_object.get("tool_call") is Some(tool_call_json) else {
        raise @json.JsonDecodeError(
          (json_path, "PreToolCall event missing 'tool_call' field"),
        )
      }
      let tool_call : @openai.ChatCompletionMessageToolCall = @json.from_json(
        tool_call_json,
        path=json_path.add_key("tool_call"),
      )
      PreToolCall(@ai.ToolCall::from_openai_tool_call(tool_call))
    }
    "PostToolCall" => {
      guard json_object.get("tool_call") is Some(tool_call_json) else {
        raise @json.JsonDecodeError(
          (json_path, "PostToolCall event missing 'tool_call' field"),
        )
      }
      let tool_call : @openai.ChatCompletionMessageToolCall = @json.from_json(
        tool_call_json,
        path=json_path.add_key("tool_call"),
      )
      let result : Result[Json, Json] = match
        (json_object.get("result"), json_object.get("error")) {
        (Some(result_json), _) => Ok(result_json)
        (None, Some(error_json)) => Err(error_json)
        (None, None) =>
          raise @json.JsonDecodeError(
            (
              json_path, "PostToolCall event missing both 'result' and 'error' fields",
            ),
          )
      }
      guard json_object.get("text") is Some(rendered_json) else {
        raise @json.JsonDecodeError(
          (json_path, "PostToolCall event missing 'text' field"),
        )
      }
      let rendered : String = @json.from_json(
        rendered_json,
        path=json_path.add_key("text"),
      )
      PostToolCall(
        @ai.ToolCall::from_openai_tool_call(tool_call),
        result~,
        rendered~,
      )
    }
    "PreConversation" => PreConversation
    "PostConversation" => PostConversation
    "MessageQueued" => {
      guard json_object.get("message") is Some(message_wrapper_json) else {
        raise @json.JsonDecodeError(
          (json_path, "MessageQueued event missing 'message' field"),
        )
      }
      guard message_wrapper_json is Object({ "id": id_json, .. }) else {
        raise @json.JsonDecodeError(
          (json_path, "Invalid 'message' field in MessageQueued event"),
        )
      }
      let id : @uuid.Uuid = @json.from_json(
        id_json,
        path=json_path.add_key("message").add_key("id"),
      )
      MessageQueued(id~)
    }
    "MessageUnqueued" => {
      guard json_object.get("message") is Some(message_wrapper_json) else {
        raise @json.JsonDecodeError(
          (json_path, "MessageUnqueued event missing 'message' field"),
        )
      }
      guard message_wrapper_json is Object({ "id": id_json, .. }) else {
        raise @json.JsonDecodeError(
          (json_path, "Invalid 'message' field in MessageUnqueued event"),
        )
      }
      let id : @uuid.Uuid = @json.from_json(
        id_json,
        path=json_path.add_key("message").add_key("id"),
      )
      MessageUnqueued(id~)
    }
    "AssistantMessage" => {
      let usage : @ai.Usage? = match json_object.get("usage") {
        None | Some(Null) => None
        Some(usage_json) =>
          Some(
            @ai.Usage::from_openai(
              @json.from_json(usage_json, path=json_path.add_key("usage")),
            ),
          )
      }
      let tool_calls : Array[@ai.ToolCall] = match
        json_object.get("tool_calls") {
        None => []
        Some(tool_calls_json) => {
          let tcs : Array[@openai.ChatCompletionMessageToolCall] = @json.from_json(
            tool_calls_json,
            path=json_path.add_key("tool_calls"),
          )
          tcs.map(@ai.ToolCall::from_openai_tool_call)
        }
      }
      let content : String = match json_object.get("content") {
        None =>
          raise @json.JsonDecodeError(
            (json_path, "AssistantMessage event missing 'content' field"),
          )
        Some(content_json) =>
          @json.from_json(content_json, path=json_path.add_key("content"))
      }
      AssistantMessage(usage~, tool_calls~, content)
    }
    "Diagnostics" => {
      guard json_object.get("diagnostics") is Some(diagnostics_json) else {
        raise @json.JsonDecodeError(
          (json_path, "Diagnostics event missing 'diagnostics' field"),
        )
      }
      let diagnostics : @diagnostics.Diagnostics = @json.from_json(
        diagnostics_json,
        path=json_path.add_key("diagnostics"),
      )
      Diagnostics(diagnostics)
    }
    "Cancelled" => Cancelled
    "UserMessage" => {
      guard json_object.get("content") is Some(content_json) else {
        raise @json.JsonDecodeError(
          (json_path, "Missing 'content' field in UserMessage event"),
        )
      }
      let content : String = @json.from_json(
        content_json,
        path=json_path.add_key("content"),
      )
      UserMessage(content)
    }
    "Failed" => {
      guard json_object.get("error") is Some(error_json) else {
        raise @json.JsonDecodeError(
          (json_path, "Missing 'error' field in Failed event"),
        )
      }
      Failed(error_json)
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
  { "id": self.id.to_json(), "desc": self.desc }
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
  match json {
    { "id": id, "desc": desc_json, .. } =>
      {
        id: @json.from_json(id),
        desc: @json.from_json(desc_json, path=json_path.add_key("desc")),
      }
    _ =>
      raise @json.JsonDecodeError(
        (
          json_path,
          "Invalid Event object: expected fields 'id' and 'desc': \{json.stringify(indent=2)}",
        ),
      )
  }
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
