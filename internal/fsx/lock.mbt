///|
extern "c" fn fsx_lock_file(fd : Int) -> Int = "moonbit_maria_fsx_lock_file"

///|
/// Acquire an advisory lock on `file`.
///
/// On error this raises an `@errno.Errno` populated from `@errno.get()`.
pub fn lock_file(file : @fs.File) -> Unit raise {
  let fd = file.fd()
  let ret = fsx_lock_file(fd)
  if ret == -1 {
    raise @errno.Errno(@errno.get())
  }
}

///|
extern "c" fn fsx_get_lock_owner(fd : Int) -> Int = "moonbit_maria_fsx_get_lock_owner"

///|
/// Return the process id that currently holds the lock for `file`.
///
/// - Returns `Some(pid)` when the file is locked.
/// - Returns `None` when the file is currently unlocked.
/// - Raises `@errno.Errno` on error.
pub fn get_lock_owner(file : @fs.File) -> Int? raise {
  let fd = file.fd()
  let pid = fsx_get_lock_owner(fd)
  if pid == -1 {
    raise @errno.Errno(@errno.get())
  } else if pid == 0 {
    None
  } else {
    Some(pid)
  }
}
