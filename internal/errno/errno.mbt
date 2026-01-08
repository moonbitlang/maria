///|
extern "c" fn errno_ERANGE() -> Int = "moonbit_maria_errno_ERANGE"

///|
pub let erange : Int = errno_ERANGE()

///|
extern "c" fn errno_ENAMETOOLONG() -> Int = "moonbit_maria_errno_ENAMETOOLONG"

///|
pub let enametoolong : Int = errno_ENAMETOOLONG()

///|
extern "c" fn errno_EEXIST() -> Int = "moonbit_maria_errno_EEXIST"

///|
pub let eexist : Int = errno_EEXIST()

///|
pub(all) suberror Errno {
  Errno(Int)
}

///|
extern "c" fn errno_strerror(errnum : Int) -> @c.Pointer[Byte] = "moonbit_maria_errno_strerror"

///|
pub impl Show for Errno with output(self : Errno, logger : &Logger) -> Unit {
  let Errno(errnum) = self
  let c_str = errno_strerror(errnum)
  if c_str.is_null() {
    logger.write_string("Errno(\{errnum}")
  } else {
    let c_len = @c.strlen(c_str).to_int()
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
extern "c" fn errno_EBADF() -> Int = "moonbit_maria_errno_EBADF"

///|
pub let ebadf : Int = errno_EBADF()

///|
extern "c" fn errno_ENOTTY() -> Int = "moonbit_maria_errno_ENOTTY"

///|
pub let enotty : Int = errno_ENOTTY()

///|
extern "c" fn errno_get() -> Int = "moonbit_maria_errno_get"

///|
pub fn get() -> Int {
  errno_get()
}

///|
extern "c" fn errno_ENOENT() -> Int = "moonbit_maria_errno_ENOENT"

///|
pub let enoent : Int = errno_ENOENT()

///|
extern "c" fn errno_EINVAL() -> Int = "moonbit_maria_errno_EINVAL"

///|
pub let einval : Int = errno_EINVAL()

///|
extern "c" fn errno_EAGAIN() -> Int = "moonbit_maria_errno_EAGAIN"

///|
pub let eagain : Int = errno_EAGAIN()

///|
extern "c" fn errno_EACCES() -> Int = "moonbit_maria_errno_EACCES"

///|
pub let eacces : Int = errno_EACCES()
