///|
/// Kind of a file-system entry.
///
/// This mirrors `@fs.FileKind` but is serializable and comparable inside
/// the `fsx` module.
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
/// A single entry returned from `list_directory`.
///
/// - `path` is the full path to the entry.
/// - `name` is the basename of the entry.
/// - `kind` describes the file-system kind of the entry.
pub struct DirectoryEntry {
  /// Full path to the entry.
  path : String
  /// Basename of the entry within the directory.
  name : String
  /// File-system kind of the entry.
  kind : FileKind
} derive(Show, Hash, Eq, Compare, ToJson)

///|
/// List all entries in the directory at `path`.
///
/// The returned entries are sorted by their derived ordering and include
/// the full path, basename and file kind for each item.
pub async fn list_directory(path : StringView) -> Array[DirectoryEntry] {
  let dir : @fs.Directory = @fs.opendir(path.to_string())
  defer dir.close()
  let entries = []
  for basename in dir.read_all() {
    let filename = @path.join(path, basename)
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
