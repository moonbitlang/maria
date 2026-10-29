///|
extern "c" fn errno_ERANGE() -> Int32 = "moonbit_maria_errno_ERANGE"

///|
pub let erange : Int32 = errno_ERANGE()

///|
extern "c" fn errno_ENAMETOOLONG() -> Int32 = "moonbit_maria_errno_ENAMETOOLONG"

///|
pub let enametoolong : Int32 = errno_ENAMETOOLONG()

///|
extern "c" fn errno_EEXIST() -> Int32 = "moonbit_maria_errno_EEXIST"

///|
pub let eexist : Int32 = errno_EEXIST()

///|
pub(all) suberror Errno {
  Errno(Int32)
}

///|
extern "c" fn errno_strerror(errnum : Int32) -> @c.Pointer[Byte] = "moonbit_maria_errno_strerror"

///|
pub impl Show for Errno with fn output(self : Errno, logger : &Logger) -> Unit {
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
pub impl ToJson for Errno with fn to_json(self : Errno) -> Json {
  Json(self.to_string())
}

///|
extern "c" fn errno_EBADF() -> Int32 = "moonbit_maria_errno_EBADF"

///|
pub let ebadf : Int32 = errno_EBADF()

///|
extern "c" fn errno_ENOTTY() -> Int32 = "moonbit_maria_errno_ENOTTY"

///|
pub let enotty : Int32 = errno_ENOTTY()

///|
extern "c" fn errno_get() -> Int32 = "moonbit_maria_errno_get"

///|
pub fn get() -> Int32 {
  errno_get()
}

///|
extern "c" fn errno_ENOENT() -> Int32 = "moonbit_maria_errno_ENOENT"

///|
pub let enoent : Int32 = errno_ENOENT()

///|
extern "c" fn errno_EINVAL() -> Int32 = "moonbit_maria_errno_EINVAL"

///|
pub let einval : Int32 = errno_EINVAL()

///|
extern "c" fn errno_EAGAIN() -> Int32 = "moonbit_maria_errno_EAGAIN"

///|
pub let eagain : Int32 = errno_EAGAIN()

///|
extern "c" fn errno_EACCES() -> Int32 = "moonbit_maria_errno_EACCES"

///|
pub let eacces : Int32 = errno_EACCES()

///|
pub extend Errno with Show::{to_string, output}

///|
pub extend Errno with ToJson::{to_json}
