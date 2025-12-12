///|
/// HTTP response writer used by `httpx` handlers.
///
/// `ResponseWriter` buffers response headers until the first write, then
/// streams the body to the underlying `@http.ServerConnection`.
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
/// Returns the mutable header map for this response.
///
/// Headers can be configured before the status line is written.
pub fn ResponseWriter::header(self : ResponseWriter) -> Header {
  self.header
}

///|
/// Sends the HTTP status line and all configured headers.
///
/// Parameters:
///
/// * `code` : HTTP status code to send.
/// * `reason` : Optional reason phrase, defaults to `httpx::reason(code)`.
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
/// Flushes any buffered response data to the client.
pub async fn ResponseWriter::flush(self : ResponseWriter) -> Unit {
  self.conn.flush()
}

///|
/// Closes the HTTP response.
///
/// Parameters:
///
/// * `self` : The response writer to close.
///
/// Note this does not necessarily close the underlying connection, depending
/// on the HTTP version and connection headers.
pub async fn ResponseWriter::close(self : ResponseWriter) -> Unit {
  self.conn.end_response()
}
