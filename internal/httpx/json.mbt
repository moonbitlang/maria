///|
struct JsonRequestReader(RequestReader)

///|
pub suberror JsonError {
  JsonError(code~ : Int, error~ : Error, message~ : String, data~ : Json)
}

///|
pub fn JsonError::new(
  code : Int,
  error : Error,
  message? : String = error.to_string(),
  data? : Json = error.to_json(),
) -> JsonError {
  JsonError(code~, error~, message~, data~)
}

///|
pub async fn JsonError::write(self : JsonError, w : ResponseWriter) -> Unit {
  let JsonError(code~, error=_, message~, data~) = self
  w.header().set("Content-Type", "application/json")
  w.write_header(code)
  let body : Json = {
    "error": { "code": code, "message": message, "data": data },
  }
  w.write(body)
}

///|
pub fn JsonRequestReader::new(r : RequestReader) -> JsonRequestReader {
  r
}

///|
pub async fn JsonRequestReader::read_json(self : JsonRequestReader) -> Json {
  let data = self.body.read_all().binary()
  let text : String = @encoding/utf8.decode(data) catch {
    error =>
      raise JsonError::new(400, error, message="Invalid UTF-8 in request body")
  }
  @json.parse(text) catch {
    error =>
      raise JsonError::new(400, error, message="Invalid JSON in request body")
  }
}

///|
pub async fn[T : @json.FromJson] JsonRequestReader::read(
  self : JsonRequestReader,
) -> T {
  let json = self.read_json()
  @json.from_json(json) catch {
    @json.JsonDecodeError(_) as error =>
      raise JsonError::new(400, error, message="Invalid request body")
  }
}

///|
struct JsonResponseWriter(ResponseWriter)

///|
pub fn JsonResponseWriter::new(w : ResponseWriter) -> JsonResponseWriter {
  w.header().set("Content-Type", "application/json")
  w
}

///|
pub async fn JsonResponseWriter::write_header(
  self : JsonResponseWriter,
  code : Int,
) -> Unit {
  self.0.write_header(code)
}

///|
pub async fn JsonResponseWriter::write_json(
  self : JsonResponseWriter,
  json : Json,
) -> Unit {
  self.0.write(json)
}

///|
pub async fn[T : ToJson] JsonResponseWriter::write(
  self : JsonResponseWriter,
  json : T,
) -> Unit {
  self.write_json(json.to_json())
}
