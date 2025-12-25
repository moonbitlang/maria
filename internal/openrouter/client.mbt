///|
priv struct Client {
  base_url : String
  api_key : String
}

///|
const BaseUrl = "https://openrouter.ai/api/v1"

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
async fn Client::get(self : Client, path : String) -> (@http.Response, Json) {
  let url = uri_path_concat(self.base_url, path)
  let (r, b) = @http.get(url, headers={
    "Authorization": "Bearer \{self.api_key}",
  })
  (r, b.json())
}

///|
async fn Client::post(
  self : Client,
  path : String,
  body : Json,
) -> (@http.Response, Json) {
  let url = uri_path_concat(self.base_url, path)
  let (r, b) = @http.post(url, body, headers={
    "Authorization": "Bearer \{self.api_key}",
    "Content-Type": "application/json",
  })
  (r, b.json())
}
