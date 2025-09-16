///|
pub async fn exists(path : StringView) -> Bool raise {
  @fs.exists(@utf8.encode(path))
}
