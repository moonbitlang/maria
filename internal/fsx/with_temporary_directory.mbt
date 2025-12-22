///|
/// Native helper for creating a unique temporary directory.
///
/// This is a thin wrapper around the platform `mkdtemp` implementation
/// and is not exposed directly to callers.
#borrow(template)
extern "c" fn fs_mkdtemp(template : FixedArray[Byte]) -> Int = "moonbit_maria_fs_mkdtemp"

///|
/// Create a temporary directory based on the provided byte template.
fn mkdtemp_bytes(bytes : Bytes) -> Bytes raise @errno.Errno {
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
/// Create a temporary directory using the given `template` pattern.
///
/// The template is typically expected to end with `XXXXXX`, which will
/// be replaced with random characters by the underlying implementation.
pub fn mkdtemp(template : String) -> String raise {
  let template = @encoding/utf8.encode(template)
  let template = mkdtemp_bytes(template)
  @encoding/utf8.decode(template)
}

///|
/// Execute `f` with a freshly-created temporary directory.
///
/// The directory is created under the system temporary directory and is
/// removed after `f` completes, both on success and on error.
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T,
) -> T {
  let os_tmpdir = @os.tmpdir()
  let template = @pathx.join(os_tmpdir, template)
  let template = mkdtemp(template)
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
