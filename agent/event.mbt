///|
/// Event type that occurs during agent conversation lifecycle.
///
/// A typical conversation lifecycle looks like this:
///
/// ```moonbit no-check
/// // add system and user messages
/// MessageAdded (system)
/// MessageAdded (user)
/// // calling agent.start()
/// PreConversation
/// while true {
///   // count tokens before request
///   TokenCounted
///   // prune context if necessary
///   ContextPruned
///   // receive assistant response
///   RequestCompleted
///   // executing tool call
///   PreToolCall
///   PostToolCall
///   MessageAdded (tool)
///   // continue to iterate if there are more messages
/// }
/// // conversation ended
/// PostConversation
/// ```
pub(all) enum Event {
  /// Event triggered when a model is loaded.
  ModelLoaded(name~ : String, model~ : @model.Model)
  /// Event triggered before a conversation starts.
  PreConversation
  /// Event triggered after a conversation ends.
  PostConversation
  /// Event triggered when a new message is added to the conversation.
  ///
  /// **Note**: This event will be triggered for system/user/tool messages.
  /// This means it's very likely that you should do some filtering based on the
  /// message role. For example, If you are listening for both MessageAdded and
  /// PostToolCall events, you would probably receive duplicate contents, one in
  /// `MessageAdded` and another in `PostToolCall`, and you may want to ignore
  /// the `MessageAdded` event for tool messages.
  ///
  /// FIXME: emit this event for assistant messages as well.
  MessageAdded(@ai.Message)
  /// Event triggered when a message is unqueued from the pending queue.
  MessageUnqueued(id~ : @uuid.Uuid)
  /// Event triggered when a message is queued to be sent to the model.
  MessageQueued(id~ : @uuid.Uuid, @ai.Message)
  /// Event triggered when a tool is added to the agent. This message will only
  /// be triggered once per agent instance.
  ToolAdded(@tool.ToolDesc)
  /// Event triggered before a tool is called.
  PreToolCall(@ai.ToolCall)
  /// Event triggered after a tool call is completed.
  ///
  /// If you are interested in the result of the tool call, then this is the
  /// event you might want to listen for. Note you should not listen for
  /// MessageAdded for tool messages as the structural representation of tool
  /// call result will be lost.
  ///
  /// The `result` field can be used to determine whether the tool call was
  /// successful or not. `rendered` field is the string representation of the
  /// tool call result, which can be used for both human and LLM consumption.
  PostToolCall(@ai.ToolCall, result~ : Result[Json, Error], rendered~ : String)
  /// Event triggered when a chat completion request is completed.
  ///
  /// If you are interested in details in the assistant response, then this is
  /// the event you might want to listen for. Compared to `MessageAdded` event,
  /// this event contains more information like `usage` and `tool_calls`.
  RequestCompleted(usage~ : @ai.Usage?, message~ : @ai.Message)
}

///|
pub impl @event.Type for Event

///|
pub impl ToJson for Event with to_json(self : Event) -> Json {
  match self {
    ModelLoaded(name~, model~) =>
      {
        "msg": "ModelLoaded",
        "name": name.to_json(),
        "model": {
          let json = model.to_json()
          if json is Object(obj) {
            obj["api_key"] = "****"
            Json::object(obj)
          } else {
            json
          }
        },
      }
    PreToolCall(tool_call) => {
      let tool_call = @openai.ChatCompletionMessageToolCall::from_ai_tool_call(
        tool_call,
      )
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
      let tool_call = @openai.ChatCompletionMessageToolCall::from_ai_tool_call(
        tool_call,
      )
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
    MessageAdded(message) =>
      {
        "msg": "MessageAdded",
        "message": @openai.ChatCompletionMessageParam::from_ai_message(message),
      }
    MessageQueued(id~, message) =>
      {
        "msg": "MessageQueued",
        "message": {
          "id": id,
          "message": @openai.ChatCompletionMessageParam::from_ai_message(
            message,
          ),
        },
      }
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
    RequestCompleted(usage~, message~) => {
      let usage = usage.map(@openai.CompletionUsage::from_ai_usage)
      let message = @openai.ChatCompletionMessageParam::from_ai_message(message)
      { "msg": "RequestCompleted", "usage": usage, "message": message }
    }
  }
}
