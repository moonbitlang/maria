pub fn cwd() -> String raise {
  @utf8.decode(@uv.cwd())
}
