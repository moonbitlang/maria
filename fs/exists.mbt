///|
pub async fn exists(path : @string.View) -> Bool raise {
  @fs.exists(@utf8.encode(path))
}
