///|
/// Opaque wrapper around platform `stat` results.
///
/// A `Stat` value is obtained via `stat` and exposes helper methods such
/// as `mtime` and `atime` for reading timestamps.
struct Stat(Bytes)

///|
extern "c" fn fs_stat_sizeof() -> Int = "moonbit_maria_fs_stat_sizeof"

///|
#borrow(path, stat)
extern "c" fn fs_stat_sync(path : Bytes, stat : FixedArray[Byte]) -> Int = "moonbit_maria_fs_stat_sync"

///|
/// Retrieve file metadata for `path`.
///
/// On success this returns a `Stat` handle; on failure it raises an
/// `@errno.Errno` with the underlying platform error code.
pub fn stat(path : StringView) -> Stat raise {
  let buf : FixedArray[Byte] = FixedArray::make(fs_stat_sizeof(), 0)
  let result = fs_stat_sync(@encoding/utf8.encode(path), buf)
  if result == 0 {
    Stat(buf.unsafe_reinterpret_as_bytes())
  } else {
    raise @errno.Errno(result)
  }
}

///|
#borrow(stat)
extern "c" fn fs_stat_get_mtime(stat : Bytes) -> Int64 = "moonbit_maria_fs_stat_get_mtime"

///|
/// Get the modification time (`mtime`) from this `Stat`.
pub fn Stat::mtime(self : Stat) -> Int64 {
  fs_stat_get_mtime(self.0)
}

///|
#borrow(stat)
extern "c" fn fs_stat_get_atime(stat : Bytes) -> Int64 = "moonbit_maria_fs_stat_get_atime"

///|
/// Get the access time (`atime`) from this `Stat`.
pub fn Stat::atime(self : Stat) -> Int64 {
  fs_stat_get_atime(self.0)
}

///|
/// Inspect the `FileKind` of the entry at `path`.
pub async fn kind(path : StringView) -> FileKind {
  FileKind::of_fs_file_kind(@fs.kind(path.to_string()))
}

///|
/// Return `true` only if `path` exists and is a regular file.
pub async fn exists_as_file(path : StringView) -> Bool {
  if !exists(path) {
    return false
  }
  return kind(path) is Regular
}
