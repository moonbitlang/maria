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
