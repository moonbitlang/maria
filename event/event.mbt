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
///   // poll external events
///   ExternalEventReceived (if any)
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
  Incoming(ExternalEvent)
  Outgoing(OutgoingEvent)
} derive(Eq, Show)

///|
pub(all) enum OutgoingEvent {
  /// Event triggered when a model is loaded.
  ModelLoaded(name~ : String, model~ : @model.Model)
  /// Event triggered before a conversation starts.
  PreConversation
  /// Event triggered after a conversation ends.
  PostConversation
  /// Event triggered when a new message is added to the conversation.
  ///
  /// **Note**: This event will be triggered for system/user messages.
  /// This means it's very likely that you should do some filtering based on the
  /// message role.
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
  /// Event triggered when a chat completion request is completed.
  ///
  /// If you are interested in details in the assistant response, then this is
  /// the event you might want to listen for. Compared to `MessageAdded` event,
  /// this event contains more information like `usage` and `tool_calls`.
  RequestCompleted(usage~ : @ai.Usage?, message~ : @ai.Message)
  /// Event triggered when an external event is received and processed.
  ExternalEventReceived(ExternalEvent)
  /// Cancelled
  Cancelled
  /// Event triggered when the todo list is updated.
  TodoUpdated(Json)
  Custom(String, Map[String, Json])
} derive(Eq, Show)

///|
pub impl ToJson for OutgoingEvent with to_json(self : OutgoingEvent) -> Json {
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
    MessageAdded(message) =>
      { "msg": "MessageAdded", "message": message.to_openai() }
    MessageQueued(id~, message) =>
      {
        "msg": "MessageQueued",
        "message": { "id": id, "message": message.to_openai() },
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
      let usage = usage.map(fn(u) { u.to_openai() })
      let message = message.to_openai()
      { "msg": "RequestCompleted", "usage": usage, "message": message }
    }
    ExternalEventReceived(external_event) =>
      { "msg": "ExternalEventReceived", "event": external_event.to_json() }
    Cancelled => { "msg": "MariaCancelled" }
    TodoUpdated(todo) => { "msg": "TodoUpdated", "todo": todo.to_json() }
    Custom(name, payload) => Json::object(payload.merge({ "msg": name }))
  }
}

///|
pub impl @json.FromJson for OutgoingEvent with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> OutgoingEvent raise @json.JsonDecodeError {
  guard json is Object({ "msg": String(msg), .. } as json_object) else {
    raise @json.JsonDecodeError(
      (json_path, "Missing 'msg' field in OutgoingEvent"),
    )
  }
  match msg {
    "ModelLoaded" => {
      guard json_object.get("name") is Some(name_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ModelLoaded event missing 'name' field"),
        )
      }
      let name : String = @json.FromJson::from_json(
        name_json,
        json_path.add_key("name"),
      )
      guard json_object.get("model") is Some(model_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ModelLoaded event missing 'model' field"),
        )
      }
      let model : @model.Model = @json.FromJson::from_json(
        model_json,
        json_path.add_key("model"),
      )
      ModelLoaded(name~, model~)
    }
    "TokenCounted" => {
      guard json_object.get("token_count") is Some(token_count_json) else {
        raise @json.JsonDecodeError(
          (json_path, "TokenCounted event missing 'token_count' field"),
        )
      }
      let token_count : Int = @json.FromJson::from_json(
        token_count_json,
        json_path.add_key("token_count"),
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
      let origin_token_count : Int = @json.FromJson::from_json(
        origin_token_count_json,
        json_path.add_key("origin_token_count"),
      )
      guard json_object.get("pruned_token_count")
        is Some(pruned_token_count_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ContextPruned event missing 'pruned_token_count' field"),
        )
      }
      let pruned_token_count : Int = @json.FromJson::from_json(
        pruned_token_count_json,
        json_path.add_key("pruned_token_count"),
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
      let rendered : String = @json.FromJson::from_json(
        rendered_json,
        json_path.add_key("text"),
      )
      PostToolCall(
        @ai.ToolCall::from_openai_tool_call(tool_call),
        result~,
        rendered~,
      )
    }
    "PreConversation" => PreConversation
    "PostConversation" => PostConversation
    "MessageAdded" => {
      guard json_object.get("message") is Some(message_json) else {
        raise @json.JsonDecodeError(
          (json_path, "MessageAdded event missing 'message' field"),
        )
      }
      let message : @openai.ChatCompletionMessageParam = @json.FromJson::from_json(
        message_json,
        json_path.add_key("message"),
      )
      MessageAdded(@ai.Message::from_openai(message))
    }
    "MessageQueued" => {
      guard json_object.get("message") is Some(message_wrapper_json) else {
        raise @json.JsonDecodeError(
          (json_path, "MessageQueued event missing 'message' field"),
        )
      }
      guard message_wrapper_json
        is Object({ "id": id_json, "message": msg_json, .. }) else {
        raise @json.JsonDecodeError(
          (json_path, "Invalid 'message' field in MessageQueued event"),
        )
      }
      let id : @uuid.Uuid = @json.FromJson::from_json(
        id_json,
        json_path.add_key("message").add_key("id"),
      )
      let message : @openai.ChatCompletionMessageParam = @json.FromJson::from_json(
        msg_json,
        json_path.add_key("message").add_key("message"),
      )
      MessageQueued(id~, @ai.Message::from_openai(message))
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
      let id : @uuid.Uuid = @json.FromJson::from_json(
        id_json,
        json_path.add_key("message").add_key("id"),
      )
      MessageUnqueued(id~)
    }
    "ToolAdded" => {
      guard json_object.get("tool") is Some(tool_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ToolAdded event missing 'tool' field"),
        )
      }
      guard tool_json
        is Object(
          {
            "name": name_json,
            "description": description_json,
            "schema": schema_json,
            ..
          }
        ) else {
        raise @json.JsonDecodeError(
          (json_path, "Invalid 'tool' field in ToolAdded event"),
        )
      }
      let name : String = @json.FromJson::from_json(
        name_json,
        json_path.add_key("tool").add_key("name"),
      )
      let description : String = @json.FromJson::from_json(
        description_json,
        json_path.add_key("tool").add_key("description"),
      )
      let schema : Json = schema_json
      ToolAdded(@tool.tool_desc(description~, name~, schema~))
    }
    "RequestCompleted" => {
      guard json_object.get("usage") is Some(usage_json) else {
        raise @json.JsonDecodeError(
          (json_path, "RequestCompleted event missing 'usage' field"),
        )
      }
      let usage : @ai.Usage? = match usage_json {
        Null => None
        Array([usage_obj]) =>
          Some(
            @ai.Usage::from_openai(
              @json.FromJson::from_json(
                usage_obj,
                json_path.add_key("usage").add_index(0),
              ),
            ),
          )
        _ =>
          raise @json.JsonDecodeError(
            (
              json_path.add_key("usage"),
              "Expected null or array with one element for usage",
            ),
          )
      }
      guard json_object.get("message") is Some(message_json) else {
        raise @json.JsonDecodeError(
          (json_path, "RequestCompleted event missing 'message' field"),
        )
      }
      let message : @openai.ChatCompletionMessageParam = @json.FromJson::from_json(
        message_json,
        json_path.add_key("message"),
      )
      RequestCompleted(usage~, message=@ai.Message::from_openai(message))
    }
    "ExternalEventReceived" => {
      guard json_object.get("event") is Some(event_json) else {
        raise @json.JsonDecodeError(
          (json_path, "ExternalEventReceived event missing 'event' field"),
        )
      }
      let external_event : ExternalEvent = ExternalEvent::from_json(
        event_json,
        json_path.add_key("event"),
      )
      ExternalEventReceived(external_event)
    }
    "MariaCancelled" => Cancelled
    "TodoUpdated" => {
      guard json_object.get("todo") is Some(todo_json) else {
        raise @json.JsonDecodeError(
          (json_path, "TodoUpdated event missing 'todo' field"),
        )
      }
      let todo : Json = @json.FromJson::from_json(
        todo_json,
        json_path.add_key("todo"),
      )
      TodoUpdated(todo)
    }
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Unknown 'msg' value in OutgoingEvent: \{msg}"),
      )
  }
}

///|
pub impl ToJson for Event with to_json(self : Event) -> Json {
  match self {
    Incoming(external_event) =>
      { "kind": "Incoming", "external_event": external_event.to_json() }
    Outgoing(outgoing_event) =>
      { "kind": "Outgoing", "outgoing_event": outgoing_event.to_json() }
  }
}

///|
pub impl @json.FromJson for Event with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Event raise @json.JsonDecodeError {
  match json {
    { "kind": "Incoming", "external_event": external_event_json, .. } =>
      Incoming(
        ExternalEvent::from_json(
          external_event_json,
          json_path.add_key("external_event"),
        ),
      )
    { "kind": "Outgoing", "outgoing_event": outgoing_event_json, .. } =>
      Outgoing(
        OutgoingEvent::from_json(
          outgoing_event_json,
          json_path.add_key("outgoing_event"),
        ),
      )
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Invalid Event object: missing or unknown 'kind' field"),
      )
  }
}
