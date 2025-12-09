///|
pub let cors : Middleware = (k : Handler) => (r, w) => {
  w.header().set("Access-Control-Allow-Origin", "*")
  w.header().set("Access-Control-Allow-Methods", "*")
  w.header().set("Access-Control-Allow-Headers", "*")
  if r.method_ == Options {
    w.write_header(@status.NoContent)
  } else {
    k(r, w)
  }
}

///|
// Real world usage example
// find all usage of `@http.post` in the codebase
// and replace it with `@httpx.post_json`
pub async fn post_json(
  uri : String,
  body : Json,
) -> (@http.Response, &@io.Data) {
  @http.post(uri, body)
}
