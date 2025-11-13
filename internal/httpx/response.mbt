///|
struct ResponseWriter {
  mut sent : Bool
  header : Header
  conn : @http.ServerConnection
}

///|
fn ResponseWriter::new(conn : @http.ServerConnection) -> ResponseWriter {
  ResponseWriter::{ sent: false, header: Header({}), conn }
}

///|
pub fn ResponseWriter::header(self : ResponseWriter) -> Header {
  self.header
}

///|
pub async fn ResponseWriter::write_header(
  self : ResponseWriter,
  code : Int,
  reason? : String = reason(code),
) -> Unit {
  guard self.sent is false else {
    println("@httpx.ResponseWriter::write_header called multiple times")
  }
  self.conn.send_response(code, reason, extra_headers=self.header.0)
  self.sent = true
}

///|
pub impl @io.Writer for ResponseWriter with write_once(
  self : ResponseWriter,
  bytes : Bytes,
  offset~ : Int,
  len~ : Int,
) -> Int {
  if !self.sent {
    self.write_header(@status.Ok)
    self.sent = true
  }
  self.conn.write_once(bytes, offset~, len~)
}

///|
pub impl @io.Writer for ResponseWriter with write_reader(
  self : ResponseWriter,
  reader : &@io.Reader,
) -> Unit {
  if !self.sent {
    self.write_header(@status.Ok)
    self.sent = true
  }
  self.conn.write_reader(reader)
}

///|
pub async fn ResponseWriter::flush(self : ResponseWriter) -> Unit {
  self.conn.flush()
}
