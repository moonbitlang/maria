///|
#borrow(template)
extern "c" fn fs_mkdtemp(template : FixedArray[Byte]) -> Int = "moonbit_maria_fs_mkdtemp"

///|
fn mkdtemp(bytes : Bytes) -> Bytes raise @errno.Errno {
  let buffer = bytes.to_fixedarray()
  let errno = fs_mkdtemp(buffer)
  if errno != 0 {
    raise @errno.Errno(errno)
  } else {
    // move the buffer ownership to Bytes
    buffer.unsafe_reinterpret_as_bytes()
  }
}

///|
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T,
) -> T {
  let os_tmpdir = @os.tmpdir()
  let template = @path.join(os_tmpdir, template)
  let template = @encoding/utf8.encode(template)
  let template = mkdtemp(template)
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
