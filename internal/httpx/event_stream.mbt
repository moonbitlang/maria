///|
/// Server-Sent Events (SSE) response writer.
///
/// `EventStreamWriter` configures the underlying `ResponseWriter` for
/// `text/event-stream` responses and provides helpers for sending events in
/// SSE format.
pub struct EventStreamWriter {
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
