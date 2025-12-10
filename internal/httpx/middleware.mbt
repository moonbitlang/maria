///|
/// Middleware wrapper that transforms one `Handler` into another.
///
/// Middlewares can be chained to build reusable HTTP processing pipelines
/// (logging, authentication, CORS, routing, etc.).
pub(all) struct Middleware((Handler) -> Handler)

///|
/// Default handler that responds with `404 Not Found`.
pub let not_found : Handler = (_, w) => w.write_header(@status.NotFound)

///|
/// Chains two middlewares together.
///
/// The `other` middleware is applied first, followed by `self`.
pub fn Middleware::chain(self : Middleware, other : Middleware) -> Middleware {
  Middleware(k => (self.0)((other.0)(k)))
}

///|
/// Executes the middleware chain using the default `not_found` handler.
pub async fn Middleware::handle(
  self : Middleware,
  r : RequestReader,
  w : ResponseWriter,
) -> Unit {
  self.handler()(r, w)
}

///|
/// Returns a `Handler` produced by applying this middleware to `not_found`.
pub fn Middleware::handler(self : Middleware) -> Handler {
  self(not_found)
}
