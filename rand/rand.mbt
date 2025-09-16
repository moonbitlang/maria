///|
let rand : @random.Rand = {
  let seed = Bytes::make(32, 0)
  let mut error = None
  try {
    let uv = @global.uv()
    let _ = uv.random(seed, 0, _ => (), e => error = Some(e))
    uv.run(Default)
    if error is Some(error) {
      raise error
    }
  } catch {
    error => abort("uv.random: \{@utf8.decode_lossy(error.to_bytes())}")
  }
  @random.Rand::chacha8(seed~)
}

///|
pub fn uint64() -> UInt64 {
  rand.uint64()
}
