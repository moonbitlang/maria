///|
/// Server-Sent Events (SSE) response writer.
///
/// `EventStreamWriter` configures the underlying `ResponseWriter` for
/// `text/event-stream` responses and provides helpers for sending events in
/// SSE format.
struct EventStreamWriter {
  w : ResponseWriter
}

///|
/// Wraps a `ResponseWriter` and configures headers for SSE.
pub fn EventStreamWriter::new(w : ResponseWriter) -> EventStreamWriter {
  w.header().set("Content-Type", "text/event-stream")
  w.header().set("Cache-Control", "no-cache")
  w.header().set("Connection", "keep-alive")
  // Disable response buffering for nginx
  w.header().set("X-Accel-Buffering", "no")
  EventStreamWriter::{ w, }
}

///|
/// Writes the HTTP status line and headers for the event stream response.
pub async fn EventStreamWriter::write_header(
  self : EventStreamWriter,
  status : Int,
) -> Unit {
  self.w.write_header(status)
}

///|
/// Writes a single SSE event to the response stream.
///
/// Parameters:
///
/// * `id` : Optional event ID.
/// * `event` : Optional event type.
/// * `data` : Optional data payload written as-is.
/// * `flush` : When true (default), flushes the response after the event.
pub async fn EventStreamWriter::write_event(
  self : EventStreamWriter,
  id? : String,
  event? : String,
  data? : &@io.Data,
  flush? : Bool = true,
) -> Unit {
  if event is Some(event) {
    self.w.write("event: \{event}\n")
  }
  if data is Some(data) {
    self.w.write(b"data: ")
    self.w.write(data)
    self.w.write(b"\n")
  }
  if id is Some(id) {
    self.w.write("id: \{id}\n")
  }
  self.w.write("\n")
  if flush {
    self.w.flush()
  }
}

///|
/// Writes an SSE event to the stream by converting the given object to an event
/// format.
///
/// Parameters:
///
/// * `self` : The event stream writer to write to.
/// * `event` : The object to convert and write as an SSE event. Must implement
///   the `ToEvent` trait.
/// * `flush` : Whether to flush the response after writing the event. Defaults
///   to `true`.
pub async fn[T : ToEvent] EventStreamWriter::write(
  self : EventStreamWriter,
  event : T,
  flush? : Bool = true,
) -> Unit {
  let sse_event = event.to_event()
  self.write_event(event?=sse_event.event, data=sse_event.data, flush~)
}

///|
/// Server-Sent Events (SSE) response reader.
///
/// `EventStreamReader` parses Server-Sent Events from an underlying reader,
/// handling event types and data payloads according to the SSE protocol.
struct EventStreamReader {
  mut last_event : String?
  r : &@io.Reader
}

///|
/// Creates a new `EventStreamReader` from the given reader.
///
/// Parameters:
///
/// * `r` : The underlying reader to parse SSE events from.
pub fn EventStreamReader::new(r : &@io.Reader) -> EventStreamReader {
  EventStreamReader::{ last_event: None, r }
}

///|
/// Represents a single Server-Sent Event.
///
/// Fields:
///
/// * `event` : Optional event type identifier.
/// * `data` : The data payload of the event.
pub struct Event {
  event : String?
  data : String
} derive(ToJson)

///|
/// Creates a new SSE event with the specified event type and data payload.
///
/// Parameters:
///
/// * `event` : Optional event type identifier that categorizes the event.
/// * `data` : The data payload content of the event.
///
/// Returns a new `Event` instance with the provided event type and data.
pub fn Event::new(event? : String, data~ : String) -> Event {
  Event::{ event, data }
}

///|
pub impl Show for Event with output(self : Event, w : &Logger) -> Unit {
  if self.event is Some(event) {
    w.write_string("event: \{event}\n")
  }
  w.write_string("data: \{self.data}\n\n")
}

///|
/// Trait for types that can be constructed from an SSE event.
///
/// Implementors can define custom parsing logic to convert SSE events
/// into domain-specific types.
pub(open) trait FromEvent {
  from_event(Event) -> Self raise
}

///|
/// A trait for types that can be converted to Server-Sent Event format.
///
/// This trait allows custom types to define how they should be represented as
/// SSE events when written to an `EventStreamWriter`. Types implementing this
/// trait can specify both the event type and data payload that will be sent
/// over the event stream.
///
/// Methods:
///
/// * `to_event(self: Self) -> Event`: Converts the instance to an SSE `Event`
///   with appropriate event type and data payload.
pub(open) trait ToEvent {
  to_event(self : Self) -> Event
}

///|
/// Reads the next SSE event from the stream.
///
/// Parses lines from the underlying reader according to the SSE protocol.
/// Returns `None` when the stream ends or no more events are available.
///
/// The reader maintains state for the last event type encountered, which
/// is associated with the next data line according to SSE semantics.
pub async fn EventStreamReader::read_event(self : EventStreamReader) -> Event? {
  while self.r.read_until("\n") is Some(line) {
    match line {
      [.. "event: ", .. event] => {
        self.last_event = Some(event.to_string())
        continue
      }
      [.. "data: ", .. data] => {
        let event = self.last_event
        self.last_event = None
        return Some(Event::{ event, data: data.to_string() })
      }
      _ => continue
    }
  }
  return None
}

///|
/// Reads and parses the next SSE event into a type implementing `FromEvent`.
///
/// This is a convenience method that reads an event and converts it to the
/// target type using the `FromEvent` trait. Returns `None` if no more events
/// are available or if parsing fails.
pub async fn[T : FromEvent] EventStreamReader::read(
  self : EventStreamReader,
) -> T? {
  let event = self.read_event()
  event.map(T::from_event)
}
