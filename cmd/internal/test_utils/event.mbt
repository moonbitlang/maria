///|
pub(all) enum ServerEvent {
  MariaQueuedMessagesSynchronized(Array[Json])
  Maria(@event.Event)
} derive(ToJson)

///|
pub impl @httpx.FromEvent for ServerEvent with from_event(event : @httpx.Event) -> ServerEvent raise {
  let { event, data } = event
  let data = @json.parse(data)
  match event {
    Some("maria.queued_messages.synchronized") =>
      ServerEvent::MariaQueuedMessagesSynchronized(@json.from_json(data))
    Some("maria") => ServerEvent::Maria(@json.from_json(data))
    _ => fail("unrecognized event type: \{event}")
  }
}

///|
pub async fn ServerEvent::collect_events(
  s : @http.Client,
  stop_at_cancel? : Bool = true,
) -> Array[ServerEvent] {
  collect_events(s, stop_at=event => if event is Maria(event) {
    if event.is_stopping() {
      return true
    }
    if stop_at_cancel && event.is_cancellation() {
      return true
    } else {
      return false
    }
  } else {
    return false
  })
}

///|
pub async fn[T : @httpx.FromEvent] collect_events(
  s : @http.Client,
  stop_at~ : (T) -> Bool,
) -> Array[T] {
  let events : Array[T] = []
  let r = @httpx.EventStreamReader::new(s)
  while r.read_event() is Some(event) {
    let event = T::from_event(event)
    events.push(event)
    if stop_at(event) {
      break
    }
  }
  return events
}

///|
pub fn redact_events(events : Array[ServerEvent]) -> Array[ServerEvent] {
  events.map(event => match event {
    MariaQueuedMessagesSynchronized(ms) => {
      for m in ms {
        if m is Object({ "id": String(_), .. } as message) {
          message["id"] = "<redacted>"
        }
      }
      return event
    }
    Maria(event) => {
      let desc : @event.EventDesc = match event.desc {
        UserMessage(_) => UserMessage("<redacted>")
        SystemPromptSet(_) => SystemPromptSet("<redacted>")
        MessageQueued(..) => MessageQueued(id=@uuid.nil)
        MessageUnqueued(..) => MessageUnqueued(id=@uuid.nil)
        AssistantMessage(_, tool_calls~, ..) =>
          AssistantMessage(
            usage=Some(
              @ai.usage(input_tokens=0, output_tokens=0, total_tokens=0),
            ),
            tool_calls=tool_calls.map(tc => @ai.tool_call(
              id=tc.id,
              name=tc.name,
              arguments="<redacted>",
            )),
            "<redacted>",
          )
        event => event
      }
      return Maria({ id: @uuid.nil, desc })
    }
  })
}

///|
pub fn extract_events_for_message(
  events : Array[ServerEvent],
  id~ : String,
  content~ : String,
) -> Array[ServerEvent] {
  events.filter(e => {
    if e is Maria({ desc: UserMessage(msg), .. }) && msg == content {
      return true
    }
    if e is Maria({ desc: MessageQueued(id=msg_id), .. }) &&
      msg_id.to_string() == id {
      return true
    }
    if e is Maria({ desc: MessageUnqueued(id=msg_id), .. }) &&
      msg_id.to_string() == id {
      return true
    }
    false
  })
}
