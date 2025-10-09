///|
pub fn getenv(key : StringView) -> String? raise {
  @uv.os_getenv(@encoding/utf8.encode(key)).map(@encoding/utf8.decode(_))
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
