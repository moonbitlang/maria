///|
pub struct EventStreamWriter {
  w : ResponseWriter
}

///|
pub fn EventStreamWriter::new(w : ResponseWriter) -> EventStreamWriter {
  w.header().set("Content-Type", "text/event-stream")
  w.header().set("Cache-Control", "no-cache")
  w.header().set("Connection", "keep-alive")
  // Disable response buffering for nginx
  w.header().set("X-Accel-Buffering", "no")
  EventStreamWriter::{ w, }
}

///|
pub async fn EventStreamWriter::write_header(
  self : EventStreamWriter,
  status : Int,
) -> Unit {
  self.w.write_header(status)
}

///|
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
