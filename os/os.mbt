///|
#borrow(key)
extern "c" fn os_getenv(key : Bytes) -> @c.Pointer[Byte] = "moonbit_maria_os_getenv"

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
  let c_str = os_getenv(@encoding/utf8.encode(key))
  if c_str.is_null() {
    return None
  }
  let len = @c.strlen(c_str).to_int()
  let buf : FixedArray[Byte] = FixedArray::make(len, 0)
  for i = 0; i < len; i = i + 1 {
    buf[i] = c_str[i]
  }
  Some(@encoding/utf8.decode(buf.unsafe_reinterpret_as_bytes()))
}

///|
#borrow(key)
extern "c" fn os_unsetenv(key : Bytes) -> Int = "moonbit_maria_os_unsetenv"

///|
pub fn unsetenv(key : StringView) -> Unit raise {
  let result = os_unsetenv(@encoding/utf8.encode(key))
  if result != 0 {
    raise @errno.Errno(result)
  }
}

///|
pub fn args() -> Array[String] {
  @env.args()
}

///|
#borrow(buf)
extern "c" fn os_getcwd(buf : FixedArray[Byte]) -> Int = "moonbit_maria_os_getcwd"

///|
pub fn cwd() -> String raise {
  let mut buf : FixedArray[Byte] = FixedArray::make(4096, 0)
  let mut result = os_getcwd(buf)
  while result == @errno.erange {
    buf = FixedArray::make(FixedArray::length(buf) * 2, 0)
    result = os_getcwd(buf)
  }
  if result == 0 {
    let len = buflen(buf)
    @encoding/utf8.decode(buf.unsafe_reinterpret_as_bytes()[0:len])
  } else {
    raise @errno.Errno(result)
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
extern "c" fn os_getuid() -> UInt = "moonbit_maria_os_getuid"

///|
#borrow(pwd, result)
extern "c" fn os_getpwuid_r(
  uid : UInt,
  pwd : FixedArray[Byte],
  buf : @c.Pointer[Byte],
  buf_len : UInt64,
  result : Ref[@c.Pointer[Unit]],
) -> Int = "moonbit_maria_os_getpwuid_r"

///|
extern "c" fn os_passwd_sizeof() -> Int = "moonbit_maria_os_passwd_sizeof"

///|
#borrow(passwd)
extern "c" fn os_passwd_get_dir(passwd : Bytes) -> @c.Pointer[Byte] = "moonbit_maria_os_passwd_get_dir"

///|
extern "c" fn sysconf_SC_GETPW_R_SIZE_MAX() -> Int = "moonbit_maria_sysconf_SC_GETPW_R_SIZE_MAX"

///|
pub fn home() -> String raise {
  if getenv("HOME") is Some(home) {
    return home
  }
  let uid = os_getuid()
  let pwd : FixedArray[Byte] = FixedArray::make(os_passwd_sizeof(), 0)
  let buf_len = sysconf_SC_GETPW_R_SIZE_MAX().to_uint64()
  let buf : @c.Pointer[Byte] = @c.malloc(buf_len)
  println("buf.len = \{buf_len}")
  let result : Ref[@c.Pointer[Unit]] = Ref::new(@c.Pointer::null())
  let errno = os_getpwuid_r(uid, pwd, buf, buf_len, result)
  if errno != 0 {
    raise @errno.Errno(errno)
  }
  let ptr = os_passwd_get_dir(pwd.unsafe_reinterpret_as_bytes())
  let len = @c.strlen(ptr).to_int()
  let dir_buf : FixedArray[Byte] = FixedArray::make(len, 0)
  for i = 0; i < len; i = i + 1 {
    dir_buf[i] = ptr[i]
  }
  @c.free(buf)
  @encoding/utf8.decode(dir_buf.unsafe_reinterpret_as_bytes())
}

///|
pub fn tmpdir() -> String raise {
  if getenv("TMPDIR") is Some(tmpdir) {
    return tmpdir
  }
  if getenv("TMP") is Some(temp) {
    return temp
  }
  if getenv("TEMP") is Some(temp) {
    return temp
  }
  if getenv("TEMPDIR") is Some(temp) {
    return temp
  }
  return "/tmp"
}

///|
extern "c" fn sysconf_SC_HOST_NAME_MAX() -> Int64 = "moonbit_maria_sysconf_SC_HOST_NAME_MAX"

///|
#borrow(name)
extern "c" fn os_gethostname(name : FixedArray[Byte]) -> Int = "moonbit_maria_os_gethostname"

///|
pub fn gethostname() -> String raise {
  let mut buf : FixedArray[Byte] = FixedArray::make(
    sysconf_SC_HOST_NAME_MAX().to_int(),
    0,
  )
  let mut result = os_gethostname(buf)
  while result == @errno.enametoolong {
    buf = FixedArray::make(FixedArray::length(buf) * 2, 0)
    result = os_gethostname(buf)
  }
  if result == 0 {
    let len = buflen(buf)
    @encoding/utf8.decode(buf.unsafe_reinterpret_as_bytes()[0:len])
  } else {
    raise @errno.Errno(result)
  }
}
