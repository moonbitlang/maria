///|
priv struct Client {
  base_url : String
  api_key : String
}

///|
const BaseUrl = "https://openrouter.ai/api/v1"

///|
fn Client::new(base_url? : String = BaseUrl, api_key~ : String) -> Client {
  Client::{ base_url, api_key }
}

///|
async fn Client::request(
  self : Client,
  path : String,
  body : Json,
) -> (@http.Response, Json) {
  let url = "\{self.base_url}\{path}"
  let (r, b) = @http.post(url, body, headers={
    "Authorization": "Bearer \{self.api_key}",
    "Content-Type": "application/json",
  })
  (r, b.json())
}
