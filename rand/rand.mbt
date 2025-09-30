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

///|
pub fn uint64() -> UInt64 raise {
  let bytes = bytes(8)
  (bytes[0].to_uint64() << 56) |
  (bytes[1].to_uint64() << 48) |
  (bytes[2].to_uint64() << 40) |
  (bytes[3].to_uint64() << 32) |
  (bytes[4].to_uint64() << 24) |
  (bytes[5].to_uint64() << 16) |
  (bytes[6].to_uint64() << 8) |
  bytes[7].to_uint64()
}
