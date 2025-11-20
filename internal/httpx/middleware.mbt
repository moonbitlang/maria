///|
pub(all) struct Middleware((Handler) -> Handler)

///|
pub let not_found : Handler = (_, w) => w.write_header(@status.NotFound)

///|
pub fn Middleware::chain(self : Middleware, other : Middleware) -> Middleware {
  Middleware(k => (self.0)((other.0)(k)))
}

///|
pub async fn Middleware::handle(
  self : Middleware,
  r : RequestReader,
  w : ResponseWriter,
) -> Unit {
  self.handler()(r, w)
}

///|
pub fn Middleware::handler(self : Middleware) -> Handler {
  self(not_found)
}
