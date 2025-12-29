///|
pub suberror ClientError {
  InvalidUrl(String)
  InvalidResponseBody(String)
} derive(Show, ToJson)

///|
pub async fn build_http_client(
  url : String,
  api_key : String,
  accept_stream~ : Bool,
) -> (@http.Client, String) {
  let (base, path) = parse_url(url)
  let headers : Map[String, String] = {
    "Authorization": "Bearer \{api_key}",
    "Content-Type": "application/json",
    "Connection": "close",
  }
  if accept_stream {
    headers["Accept"] = "text/event-stream"
  }
  let client = @http.Client::new(base, headers~)
  (client, path)
}

///|
pub async fn read_sse_line(reader : &@io.Reader) -> String? {
  for {
    guard reader.read_until("\n") is Some(line) else { return None }
    guard line is [.. "data: ", .. rest] else { continue }
    let data = rest.trim().to_string()
    if data == "[DONE]" {
      return None
    }
    return Some(data)
  }
}

///|
pub fn[T : @json.FromJson] parse_json_response(
  payload : String,
) -> T raise ClientError {
  try {
    let json = @json.parse(payload)
    @json.from_json(json)
  } catch {
    err => raise InvalidResponseBody(err.to_string())
  }
}
