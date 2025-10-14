///|
#borrow(buf)
extern "c" fn rand_bytes(buf : Bytes) -> Int = "moonbit_maria_rand_bytes"

///|
pub fn bytes(n : Int) -> Bytes raise @errno.Errno {
  let buf = Bytes::make(n, 0)
  let errno = rand_bytes(buf)
  if errno != 0 {
    raise @errno.Errno(errno)
  }
  buf
}

///|
pub fn chacha8() -> @random.Rand raise @errno.Errno {
  @random.Rand::chacha8(seed=bytes(32))
}
