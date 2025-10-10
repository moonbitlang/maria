///|
fn strlen(c_str : @c.Pointer[Byte]) -> Int {
  for i = 0; ; i = i + 1 {
    if c_str[i] == 0 {
      return i
    }
  }
}

///|
extern "c" fn errno_ERANGE() -> Int = "moonbit_maria_errno_ERANGE"

///|
pub let erange : Int = errno_ERANGE()

///|
extern "c" fn errno_ENAMETOOLONG() -> Int = "moonbit_maria_errno_ENAMETOOLONG"

///|
pub let enametoolong : Int = errno_ENAMETOOLONG()

///|
pub(all) suberror Errno Int

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
pub impl ToJson for Errno with to_json(self : Errno) -> Json {
  self.to_string().to_json()
}

///|
pub extern "c" fn get() -> Int = "moonbit_maria_errno_get"

///|
pub extern "c" fn set(err : Int) -> Int = "moonbit_maria_errno_set"
