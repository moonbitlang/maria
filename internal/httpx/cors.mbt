///|
/// Simple CORS middleware that allows all origins, methods and headers.
///
/// This is suitable for development or trusted environments. For production
/// deployments, consider tightening the allowed origins and methods.
pub let cors : Middleware = (k : Handler) => (r, w) => {
  w
  .header()
  .config({
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "*",
    "Access-Control-Allow-Headers": "*",
  })
  if r.method_ == Options {
    w.write_header(@status.NoContent)
  } else {
    k(r, w)
  }
}

///|
/// Convenience helper mirroring `@http.post` for JSON bodies.
///
/// Real world usage example: find all usages of `@http.post` in the
/// codebase and replace them with `@httpx.post_json` to make the
/// intent explicit.
pub async fn post_json(
  uri : String,
  body : Json,
) -> (@http.Response, &@io.Data) {
  @http.post(uri, body)
}
