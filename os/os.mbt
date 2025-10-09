///|
#borrow(key)
extern "c" fn c_getenv(key : Bytes) -> @c.Pointer[Byte] = "moonbit_maria_os_get_env"

///|
pub fn getenv(key : StringView) -> String? raise {
  let c_str = c_getenv(@encoding/utf8.encode(key))
  if c_str.is_null() {
    return None
  }
  let len = for i = 0; c_str[i] != 0; i = i + 1 {

  } else {
    i
  }
  let buf : FixedArray[Byte] = FixedArray::make(len, 0)
  for i = 0; i < len; i = i + 1 {
    buf[i] = c_str[i]
  }
  Some(@encoding/utf8.decode(buf.unsafe_reinterpret_as_bytes()))
}

///|
pub fn args() -> Array[String] {
  @env.args()
}

///|
pub fn cwd() -> String raise {
  @encoding/utf8.decode(@uv.cwd())
}

///|
pub fn now() -> @time.ZonedDateTime raise {
  let tv : FixedArray[Int64] = [0, 0]
  c_gettimeofday(tv)
  @time.unix(tv[0], nanosecond=(tv[1] * 1000).to_int())
}

///|
#borrow(tv)
extern "c" fn c_gettimeofday(tv : FixedArray[Int64]) = "moonbit_maria_os_gettimeofday"

///|
pub fn now_ms() -> Int64 {
  let tv : FixedArray[Int64] = [0, 0]
  c_gettimeofday(tv)
  tv[0] * 1000 + tv[1] / 1000
}

///|
pub fn home() -> String raise {
  @encoding/utf8.decode(@uv.os_homedir())
}
