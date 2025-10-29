///|
pub async fn make_directory(
  path : StringView,
  recursive? : Bool = false,
  exists_ok? : Bool = false,
) -> Unit {
  if !recursive {
    if !(path == "." || path == "" || @fs.exists(path)) {
      @fs.mkdir(path, permission=0o755)
    } else if exists_ok {
      @fs.mkdir(path, permission=0o755) catch {
        @os_error.OSError(errno, ..) if errno == @errno.eexist => ()
        error => raise error
      }
    }
  } else {
    let path = @path.Path::parse(path + "/")
    let prefix_path = @path.Path::parse(path.prefix())
    let path_builder = @path.PathBuilder::from_path(prefix_path)
    let dirs = path.directory()
    loop dirs[:] {
      [] => break
      [dir, .. dirs] => {
        path_builder.add_directory(dir)
        let str_path = path_builder.to_string()
        if !@fs.exists(str_path) {
          @fs.mkdir(str_path, permission=0o755)
        } else if exists_ok {
          @fs.mkdir(str_path, permission=0o755) catch {
            @os_error.OSError(errno, ..) if errno == @errno.eexist => ()
            error => raise error
          }
        }
        continue dirs
      }
    }
  }
}
