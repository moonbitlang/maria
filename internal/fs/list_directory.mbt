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
} derive(Show, Hash, Eq, Compare, ToJson)

///|
fn FileKind::of_fs_file_kind(file_kind : @fs.FileKind) -> FileKind {
  match file_kind {
    @fs.FileKind::Unknown => Unknown
    @fs.FileKind::Regular => Regular
    @fs.FileKind::Directory => Directory
    @fs.FileKind::SymLink => SymLink
    @fs.FileKind::Socket => Socket
    @fs.FileKind::Pipe => Pipe
    @fs.FileKind::BlockDevice => BlockDevice
    @fs.FileKind::CharDevice => CharDevice
  }
}

///|
pub struct DirectoryEntry {
  path : String
  name : String
  kind : FileKind
} derive(Show, Hash, Eq, Compare, ToJson)

///|
pub async fn list_directory(path : StringView) -> Array[DirectoryEntry] {
  let dir : @fs.Directory = @fs.opendir(path.to_string())
  defer dir.close()
  let entries = []
  let path = @path.Path::parse(path + "/")
  for basename in dir.read_all() {
    let path_builder = @path.PathBuilder::from_path(path)
    path_builder.set_basename(basename)
    let filename = path_builder.to_string()
    let kind = @fs.kind(filename, follow_symlink=false)
    entries.push(DirectoryEntry::{
      path: filename,
      name: basename,
      kind: FileKind::of_fs_file_kind(kind),
    })
  }
  entries.sort()
  entries
}
