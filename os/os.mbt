///|
#borrow(key)
extern "c" fn c_getenv(key : Bytes) -> @c.Pointer[Byte] = "moonbit_maria_os_get_env"

///|
fn strlen(c_str : @c.Pointer[Byte]) -> Int {
  for i = 0; ; i = i + 1 {
    if c_str[i] == 0 {
      return i
    }
  }
}

///|
fn buflen(buf : FixedArray[Byte]) -> Int {
  for i = 0; i < FixedArray::length(buf); i = i + 1 {
    if buf[i] == 0 {
      return i
    }
  }
  FixedArray::length(buf)
}

///|
pub fn getenv(key : StringView) -> String? raise {
  let c_str = c_getenv(@encoding/utf8.encode(key))
  if c_str.is_null() {
    return None
  }
  let len = strlen(c_str)
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
extern "c" fn errno_ERANGE() -> Int = "moonbit_maria_errno_ERANGE"

///|
let erange : Int = errno_ERANGE()

///|
#borrow(buf)
extern "c" fn os_getcwd(buf : FixedArray[Byte]) -> Int = "moonbit_maria_os_getcwd"

///|
pub suberror Errno Int

///|
extern "c" fn errno_strerror(errnum : Int) -> @c.Pointer[Byte] = "moonbit_maria_errno_strerror"

///|
pub impl Show for Errno with output(self : Errno, logger : &Logger) -> Unit {
  let Errno(errnum) = self
  let c_str = errno_strerror(errnum)
  if c_str.is_null() {
    logger.write_string("Errno(\{errnum}")
  } else {
    let c_len = strlen(c_str)
    let buf : FixedArray[Byte] = FixedArray::make(c_len, 0)
    for i = 0; i < c_len; i = i + 1 {
      buf[i] = c_str[i]
    }
    let str = @encoding/utf8.decode_lossy(buf.unsafe_reinterpret_as_bytes())
    logger.write_string(str)
  }
}

///|
pub fn cwd() -> String raise {
  let mut buf : FixedArray[Byte] = FixedArray::make(4096, 0)
  let mut result = os_getcwd(buf)
  while result == erange {
    buf = FixedArray::make(FixedArray::length(buf) * 2, 0)
    result = os_getcwd(buf)
  }
  if result == 0 {
    let len = buflen(buf)
    @encoding/utf8.decode(buf.unsafe_reinterpret_as_bytes()[0:len])
  } else {
    raise Errno(result)
  }
}

///|
pub fn now() -> @time.ZonedDateTime raise {
  let tv : FixedArray[Int64] = [0, 0]
  os_gettimeofday(tv)
  @time.unix(tv[0], nanosecond=(tv[1] * 1000).to_int())
}

///|
#borrow(tv)
extern "c" fn os_gettimeofday(tv : FixedArray[Int64]) = "moonbit_maria_os_gettimeofday"

///|
pub fn now_ms() -> Int64 {
  let tv : FixedArray[Int64] = [0, 0]
  os_gettimeofday(tv)
  tv[0] * 1000 + tv[1] / 1000
}

///|
pub fn home() -> String raise {
  @encoding/utf8.decode(@uv.os_homedir())
}
