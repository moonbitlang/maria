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
#borrow(key, value)
extern "c" fn os_setenv(key : Bytes, value : Bytes, overwrite : Int) -> Int = "moonbit_maria_os_setenv"

///|
pub fn setenv(
  key : StringView,
  value : StringView,
  overwrite? : Bool = true,
) -> Unit raise {
  let result = os_setenv(
    @encoding/utf8.encode(key),
    @encoding/utf8.encode(value),
    if overwrite {
      1
    } else {
      0
    },
  )
  if result != 0 {
    raise @errno.Errno(result)
  }
}

///|
pub fn args() -> Array[String] {
  @env.args()
}

///|
pub fn cwd() -> String raise {
  @env.current_dir().unwrap_or_error(
    Failure("failed to get current working directory"),
  )
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

///|
#borrow(path)
extern "c" fn os_chdir(path : Bytes) -> Int = "moonbit_maria_os_chdir"

///|
pub fn chdir(path : StringView) -> Unit raise {
  let result = os_chdir(@encoding/utf8.encode(path))
  if result != 0 {
    raise @errno.Errno(result)
  }
}

///|
extern "c" fn os_exit(code : Int) = "exit"

///|
pub fn[X] exit(code : Int) -> X {
  os_exit(code)
  panic()
}

///|
#borrow(buf)
extern "c" fn os_executable(buf : FixedArray[Byte]) -> Int = "moonbit_maria_os_executable"

///|
/// Returns the path of the current executable. Note that the returned path
/// may be a symbolic link and not the real file, so make sure to resolve it
/// before calling spawn.
///
/// Implementations:
///
/// - macOS: `_NSGetExecutablePath()`
/// - Linux: `readlink("/proc/self/exe")`
pub fn executable() -> String raise {
  let mut buf : FixedArray[Byte] = FixedArray::make(1024, 0)
  let mut size = os_executable(buf)
  if size == -1 {
    raise @errno.Errno(@errno.get())
  }
  while size > buf.length() {
    buf = FixedArray::make(size, 0)
    size = os_executable(buf)
    if size == -1 {
      raise @errno.Errno(@errno.get())
    }
  }
  let new_buf : FixedArray[Byte] = FixedArray::make(size, 0)
  new_buf.unsafe_blit(0, buf, 0, size)
  @encoding/utf8.decode(new_buf.unsafe_reinterpret_as_bytes())
}
