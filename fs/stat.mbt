///|
struct Stat(Bytes)

///|
extern "c" fn fs_stat_sizeof() -> Int = "moonbit_maria_fs_stat_sizeof"

///|
#borrow(path, stat)
extern "c" fn fs_stat_sync(path : Bytes, stat : FixedArray[Byte]) -> Int = "moonbit_maria_fs_stat_sync"

///|
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
pub fn Stat::mtime(self : Stat) -> Int64 {
  fs_stat_get_mtime(self.0)
}

///|
#borrow(stat)
extern "c" fn fs_stat_get_atime(stat : Bytes) -> Int64 = "moonbit_maria_fs_stat_get_atime"

///|
pub fn Stat::atime(self : Stat) -> Int64 {
  fs_stat_get_atime(self.0)
}

///|
pub async fn kind(path : StringView) -> FileKind {
  FileKind::of_fs_file_kind(@fs.kind(path.to_string()))
}
