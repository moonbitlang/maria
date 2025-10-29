///|
pub async fn make_directory(
  path : StringView,
  recursive? : Bool = false,
  exists_ok? : Bool = false,
) -> Unit {
  let dirs = []
  for dir = path {
    let dir = dir.to_string()
    if dir == "." || dir == "" || @fs.exists(dir) {
      break
    }
    dirs.push(dir)
    if recursive {
      continue @path.dirname(dir)
    } else {
      break
    }
  }
  for i in 0..<dirs.length() {
    let dir = dirs[dirs.length() - 1 - i]
    if exists_ok {
      @fs.mkdir(dir, permission=0o755) catch {
        @os_error.OSError(errno, ..) if errno == @errno.eexist => ()
        error => raise error
      }
    } else {
      @fs.mkdir(dir, permission=0o755)
    }
  }
}
