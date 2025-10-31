///|
/// 
/// TODO: wait for a more robust approach.
/// 
/// 1. Node.js [process.platform](https://nodejs.org/docs/latest/api/process.html#processplatform)
/// 2. Posix [uname](https://man7.org/linux/man-pages/man2/uname.2.html)
/// 3. Windows [GetNativeSystemInfo](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getnativesysteminfo)
/// 
/// `moonbitlang/x` should implemente this functionality like node.js `process.platform`
/// 
/// https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables
fn detect_platform() -> @path.PathStyle {
  let env = @sys.get_env_vars()
  if env.contains("WINDIR") {
    Win
  } else {
    Unix
  }
}

///|
pub let path_style : @path.PathStyle = detect_platform()
