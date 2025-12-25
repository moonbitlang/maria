///|
priv struct Client {
  base_url : String
  api_key : String
}

///|
const BaseUrl = "https://api.openai.com/v1"

///|
fn Client::new(base_url? : String = BaseUrl, api_key~ : String) -> Client {
  { base_url, api_key }
}

///|
fn uri_path_concat(base_url : String, path : String) -> String {
  if path is ['/', ..] {
    "\{base_url}\{path}"
  } else {
    "\{base_url}/\{path}"
  }
}

///|
async fn Client::post(
  self : Client,
  path : String,
  body : Json,
) -> (@http.Response, &@io.Data) {
  let url = uri_path_concat(self.base_url, path)
  let (r, b) = @http.post(url, body, headers={
    "Authorization": "Bearer \{self.api_key}",
    "Content-Type": "application/json",
  })
  (r, b)
}

///|
async fn Client::post_stream(
  self : Client,
  path : String,
  body : Json,
) -> (@http.Response, @http.Client) {
  let url = uri_path_concat(self.base_url, path)
  let c = @http.post_stream(url, headers={
    "Authorization": "Bearer \{self.api_key}",
    "Content-Type": "application/json",
    "Accept": "text/event-stream",
  })
  c.write(body)
  let r = c.end_request()
  (r, c)
}
