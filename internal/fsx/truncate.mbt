///|
extern "c" fn fsx_ftruncate(fd : Int, length : Int64) -> Int = "moonbit_maria_fsx_ftruncate"

///|
pub fn truncate(file : @fs.File, length : Int64) -> Unit raise {
  let result = fsx_ftruncate(file.fd(), length)
  if result != 0 {
    raise @errno.Errno(@errno.get())
  }
}
