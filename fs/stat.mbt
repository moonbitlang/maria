///|
struct Stat(@uv.Stat)

///|
pub fn stat(path : StringView) -> Stat raise {
  Stat(@global.uv().fs_stat_sync(@encoding/utf8.encode(path)))
}

///|
pub fn Stat::mtime(self : Stat) -> Int64 {
  // Convert to milliseconds
  self.0.mtim_sec() * 1_000 + self.0.mtim_nsec() / 1_000_000
}
