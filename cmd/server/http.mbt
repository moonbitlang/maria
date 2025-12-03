///|
priv struct JsonRequestReader {
  r : @httpx.RequestReader
}

///|
fn JsonRequestReader::new(r : @httpx.RequestReader) -> JsonRequestReader {
  JsonRequestReader::{ r, }
}

///|
async fn JsonRequestReader::read_json(self : JsonRequestReader) -> Json {
  let data = self.r.body.read_all().binary()
  let text : String = @encoding/utf8.decode(data) catch {
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid UTF-8 in request body: \{bytes}",
        },
      })
  }
  @json.parse(text) catch {
    error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid JSON in request body: \{error}",
        },
      })
  }
}

///|
async fn[T : @json.FromJson] JsonRequestReader::read(
  self : JsonRequestReader,
) -> T {
  let json = self.read_json()
  @json.from_json(json) catch {
    @json.JsonDecodeError(_) as error =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid request body: \{error}",
          "data": { "error": error, "body": json },
        },
      })
  }
}

///|
priv struct JsonResponseWriter {
  w : @httpx.ResponseWriter
}

///|
fn JsonResponseWriter::new(w : @httpx.ResponseWriter) -> JsonResponseWriter {
  w.header().set("Content-Type", "application/json")
  JsonResponseWriter::{ w, }
}

///|
async fn JsonResponseWriter::write_header(
  self : JsonResponseWriter,
  code : Int,
) -> Unit {
  self.w.write_header(code)
}

///|
async fn JsonResponseWriter::write_json(
  self : JsonResponseWriter,
  json : Json,
) -> Unit {
  self.w.write(json)
}

///|
async fn[T : ToJson] JsonResponseWriter::write(
  self : JsonResponseWriter,
  json : T,
) -> Unit {
  self.write_json(json.to_json())
}
