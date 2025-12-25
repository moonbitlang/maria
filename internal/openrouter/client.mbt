///|
priv struct Client {
  host_uri : String
  base_path : String
  api_key : String
  clients : @aqueue.Queue[@http.Client]
}

///|
const BaseUrl = "https://openrouter.ai/api/v1"

///|
fn Client::new(
  base_url? : String = BaseUrl,
  api_key~ : String,
) -> Client raise @uri.ParseError {
  let uri = @uri.Uri::parse(base_url)
  let uri_buf = StringBuilder::new()
  uri_buf.write_stringview(uri.scheme)
  if uri.authority is Some(authority) {
    uri_buf.write_string("://")
    if authority.userinfo is Some(userinfo) {
      uri_buf.write_stringview(userinfo)
      uri_buf.write_char('@')
    }
    uri_buf.write_stringview(authority.host)
    if authority.port is Some(port) {
      uri_buf.write_char(':')
      port.output(uri_buf)
    }
  }
  let host_uri = uri_buf.to_string()
  let base_path = uri.path.join("/")
  { host_uri, base_path, api_key, clients: @aqueue.Queue::new(kind=Unbounded) }
}

///|
async fn Client::new_http_client(self : Client) -> @http.Client {
  if self.clients.try_get() is Some(client) {
    return client
  }
  @http.Client::new(self.host_uri, headers={
    "Authorization": "Bearer \{self.api_key}",
  })
}

///|
fn uri_path_concat(base : String, path : String) -> String {
  if path is ['/', ..] {
    "/\{base}\{path}"
  } else {
    "/\{base}/\{path}"
  }
}

///|
async fn Client::get(self : Client, path : String) -> (@http.Response, Json) {
  let path = uri_path_concat(self.base_path, path)
  let client = self.new_http_client()
  defer ignore(self.clients.try_put(client))
  client.request(Get, path)
  let r = client.end_request()
  let b = client.read_all()
  (r, b.json())
}

///|
async fn Client::post(
  self : Client,
  path : String,
  body : Json,
) -> (@http.Response, Json) {
  let path = uri_path_concat(self.base_path, path)
  let client = self.new_http_client()
  defer ignore(self.clients.try_put(client))
  client.request(Post, path, extra_headers={
    "Content-Type": "application/json",
  })
  client.write(body)
  let r = client.end_request()
  let b = client.read_all()
  (r, b.json())
}

///|
fn Client::close(self : Client) -> Unit {
  while self.clients.try_get() is Some(client) {
    client.close()
  }
}
