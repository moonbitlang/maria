///|
#borrow(template)
extern "c" fn fs_mkdtemp(template : Bytes) -> Int = "moonbit_maria_fs_mkdtemp"

///|
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T,
) -> T {
  let os_tmpdir = @os.tmpdir()
  let template = @path.join(os_tmpdir, template)
  let template = @encoding/utf8.encode(template)
  let errno = fs_mkdtemp(template)
  if errno != 0 {
    raise @errno.Errno(errno)
  }
  let template = @encoding/utf8.decode(template)
  try f(template) catch {
    error => {
      @fs.rmdir(template, recursive=true) catch {
        _ => ()
      }
      raise error
    }
  } noraise {
    value => {
      @fs.rmdir(template, recursive=true) catch {
        _ => ()
      }
      value
    }
  }
}
