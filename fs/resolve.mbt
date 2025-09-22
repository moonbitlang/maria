///|
pub fn resolve(path : StringView) -> String raise {
  @encoding/utf8.decode(
    @global.uv().fs_realpath_sync(@encoding/utf8.encode(path)),
  )
}
