///|
pub fn cwd() -> String raise {
  @encoding/utf8.decode(@uv.cwd())
}
