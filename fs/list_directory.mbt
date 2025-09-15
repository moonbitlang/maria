///|
pub async fn list_directory(path : @string.View) -> Array[String] raise {
  let dirname = @utf8.encode(path)
  let dir = @fs.opendir(dirname)
  defer dir.close()
  let entries = []
  for basename in dir.read_all() {
    let filename = @path.join(dirname, basename)
    let file = @fs.open(filename, mode=ReadOnly)
    defer file.close()
    let basename : Bytes = match file.kind() {
      Directory => [..basename, @path.sep]
      _ => basename
    }
    entries.push(@utf8.decode(basename))
  }
  entries.sort()
  entries
}
