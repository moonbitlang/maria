///|
pub fn cors(next : Handler) -> Handler {
  (r, w) => {
    w.header().set("Access-Control-Allow-Origin", "*")
    w.header().set("Access-Control-Allow-Methods", "*")
    w.header().set("Access-Control-Allow-Headers", "*")
    if r.method_ == Options {
      w.write_header(@status.NoContent)
    } else {
      (next.0)(r, w)
    }
  }
}
