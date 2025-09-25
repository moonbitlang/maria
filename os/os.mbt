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
  let ts = @uv.clock_gettime(Realtime)
  @time.unix(ts.sec(), nanosecond=ts.nsec())
}
