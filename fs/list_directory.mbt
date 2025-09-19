///|
pub enum FileKind {
  Unknown
  Regular
  Directory
  SymLink
  Socket
  Pipe
  BlockDevice
  CharDevice
} derive(Hash, Eq, Compare, ToJson)

///|
pub struct DirectoryEntry {
  path : String
  name : String
  kind : FileKind
} derive(Hash, Eq, Compare, ToJson)

///|
pub async fn list_directory(path : StringView) -> Array[DirectoryEntry] {
  let dirname = @encoding/utf8.encode(path)
  let dir : @fs.Directory = @fs.opendir(dirname)
  defer dir.close()
  let entries = []
  for basename in dir.read_all() {
    let filename = @path.join(dirname, basename)
    let file = @fs.open(filename, mode=ReadOnly)
    defer file.close()
    entries.push(DirectoryEntry::{
      path: @encoding/utf8.decode(filename),
      name: @encoding/utf8.decode(basename),
      kind: match file.kind() {
        Unknown => Unknown
        Regular => Regular
        Directory => Directory
        SymLink => SymLink
        Socket => Socket
        Pipe => Pipe
        BlockDevice => BlockDevice
        CharDevice => CharDevice
      },
    })
  }
  entries.sort()
  entries
}
