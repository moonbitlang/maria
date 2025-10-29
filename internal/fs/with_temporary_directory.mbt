///|
#borrow(template)
extern "c" fn fs_mkdtemp(template : Bytes) -> Int = "moonbit_maria_fs_mkdtemp"

///|
pub async fn[T] with_temporary_directory(
  template : String,
  f : async (String) -> T,
) -> T {
  let path = try! @path.Path::parse(@os.tmpdir() + "/")
  let path_builder = @path.PathBuilder::from_path(path)
  let utf16_path_template = try {
    path_builder.add_directory(template)
    let path = path_builder.to_string()
    // provide a flag for string not trailing slash 
    try! path[0:path.length() - 1].to_string()
    // workaround 
  } catch {
    @path.PathError(_) => template
  }
  let template = @encoding/utf8.encode(utf16_path_template)
  // FIXME: `fs_mkdtemp` modifies the `template` is unexpected behavior.
  let errno = fs_mkdtemp(template)
  if errno != 0 {
    raise @errno.Errno(errno)
  }
  let utf16_template = @encoding/utf8.decode(template)
  try f(utf16_template) catch {
    error => {
      @fs.rmdir(utf16_template, recursive=true) catch {
        _ => ()
      }
      raise error
    }
  } noraise {
    value => {
      @fs.rmdir(utf16_template, recursive=true) catch {
        _ => ()
      }
      value
    }
  }
}
