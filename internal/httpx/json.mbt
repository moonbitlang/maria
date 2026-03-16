///|
/// Wrapper around `RequestReader` for JSON-based HTTP APIs.
///
/// `JsonRequestReader` provides helpers for decoding the request body as
/// raw JSON or into strongly-typed values via `@json.FromJson`.
pub struct JsonRequestReader(RequestReader)

///|
pub suberror JsonError {
  JsonError(code~ : Int, message~ : String, data~ : Json)
}

///|
/// Constructs a new JSON error payload from a lower-level error.
///
/// Parameters:
///
/// * `code` : HTTP status code to return.
/// * `error` : Underlying error that triggered this JSON error.
/// * `message` : Optional human-friendly error message.
/// * `data` : Optional structured error payload.
pub fn JsonError::new(
  code : Int,
  message : String,
  data? : Json = {},
) -> JsonError {
  JsonError(code~, message~, data~)
}

///|
/// Converts a generic error into a structured JSON error response.
///
/// Parameters:
///
/// * `code` : The HTTP status code to associate with this error.
/// * `error` : The original error to be converted.
/// * `data` : Optional JSON payload containing additional error details.
///   Defaults to the JSON representation of the original error.
///
/// Returns a new `JsonError` instance with the provided status code, the string
/// representation of the original error as the message, and the specified data
/// payload.
pub fn JsonError::from_error(
  code : Int,
  error : Error,
  message? : String = error.to_string(),
  data? : Json = error.to_json(),
) -> JsonError {
  JsonError(code~, message~, data~)
}

///|
/// Writes the JSON error response to the given `ResponseWriter`.
pub async fn JsonError::write(self : JsonError, w : ResponseWriter) -> Unit {
  let JsonError(code~, message~, data~) = self
  w.header().set("Content-Type", "application/json")
  w.write_header(code)
  let body : Json = {
    "error": { "code": code, "message": message, "data": data },
  }
  w.write(body)
}

///|
/// Creates a JSON-aware request reader from a plain `RequestReader`.
pub fn JsonRequestReader::new(r : RequestReader) -> JsonRequestReader {
  r
}

///|
/// Reads the entire request body and parses it as JSON.
///
/// Raises `JsonError` with status `400` for invalid UTF-8 or JSON payloads.
pub async fn JsonRequestReader::read_json(self : JsonRequestReader) -> Json {
  let data = self.body.read_all().binary()
  let text : String = @encoding/utf8.decode(data) catch {
    error =>
      raise JsonError::from_error(
        400,
        error,
        message="Invalid UTF-8 in request body",
      )
  }
  @json.parse(text) catch {
    error =>
      raise JsonError::from_error(
        400,
        error,
        message="Invalid JSON in request body",
      )
  }
}

///|
/// Deserializes the request body into a value of type `T`.
///
/// Raises `JsonError` with status `400` when JSON decoding fails.
pub async fn[T : @json.FromJson] JsonRequestReader::read(
  self : JsonRequestReader,
) -> T {
  let json = self.read_json()
  @json.from_json(json) catch {
    @json.JsonDecodeError(_) as error =>
      raise JsonError::from_error(400, error, message="Invalid request body")
  }
}

///|
/// JSON response writer that automatically sets the `Content-Type` header.
struct JsonResponseWriter(ResponseWriter)

///|
/// Wraps a `ResponseWriter` and sets `Content-Type: application/json`.
pub fn JsonResponseWriter::new(w : ResponseWriter) -> JsonResponseWriter {
  w.header().set("Content-Type", "application/json")
  w
}

///|
/// Writes only the status line and headers for a JSON response.
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
/// Serializes a value to JSON and writes it as the response body.
pub async fn[T : ToJson] JsonResponseWriter::write(
  self : JsonResponseWriter,
  json : T,
) -> Unit {
  self.write_json(json.to_json())
}
