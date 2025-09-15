///|
pub async fn make_directory(path : @string.View) -> Unit raise {
  let dirs = []
  for dir = @utf8.encode(path) {
    let dir = dir
    if dir == "." || dir == "" || @fs.exists(dir) {
      break
    }
    dirs.push(dir)
    continue @path.dirname(dir).to_bytes()
  }
  for i in 0..<dirs.length() {
    let dir = dirs[dirs.length() - 1 - i]
    @fs.mkdir(dir, permission=0o755)
  }
}
