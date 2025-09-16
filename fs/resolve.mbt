///|
pub fn resolve(path : StringView) -> String raise {
  @utf8.decode(@global.uv().fs_realpath_sync(@utf8.encode(path)))
}
