///|
pub fn bytes(n : Int) -> Bytes raise {
  let seed = Bytes::make(n, 0)
  let uv = @global.uv()
  let mut error = None
  let _ = uv.random(seed, 0, _ => (), e => error = Some(e))
  uv.run(Default)
  if error is Some(error) {
    raise error
  }
  seed
}

///|
pub fn chacha8(seed? : Bytes) -> @random.Rand {
  @random.Rand::chacha8(seed?)
}
