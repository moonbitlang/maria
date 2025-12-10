///|
/// Low-level wrapper around the C `_exit` function.
///
/// This function terminates the current process immediately without running
/// any cleanup handlers. It is used by `exit` and should not be called
/// directly from user code in most cases.
extern "c" fn _exit(status : Int) = "exit"

///|
/// Terminates the current process with the given exit status.
///
/// This function never returns; it delegates to the C `_exit` function and
/// then calls `abort` as a safeguard if control ever comes back.
pub fn[T] exit(status : Int) -> T {
  _exit(status)
  abort("exit should never return")
}
