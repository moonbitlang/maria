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
  let unique_dir = mkdtemp(template)
  let utf16_unique_dir = @encoding/utf8.decode(unique_dir)
  try f(utf16_unique_dir) catch {
    error => {
      @fs.rmdir(utf16_unique_dir, recursive=true) catch {
        _ => ()
      }
      raise error
    }
  } noraise {
    value => {
      @fs.rmdir(utf16_unique_dir, recursive=true) catch {
        _ => ()
      }
      value
    }
  }
}
