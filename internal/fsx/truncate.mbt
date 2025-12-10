///|
extern "c" fn fsx_ftruncate(fd : Int, length : Int64) -> Int = "moonbit_maria_fsx_ftruncate"

///|
/// Truncate `file` to the given `length` in bytes.
///
/// On failure this raises an `@errno.Errno` populated from `@errno.get()`.
pub fn truncate(file : @fs.File, length : Int64) -> Unit raise {
  let result = fsx_ftruncate(file.fd(), length)
  if result != 0 {
    raise @errno.Errno(@errno.get())
  }
}
