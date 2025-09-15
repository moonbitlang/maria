///|
pub async fn remove(path : @string.View) -> Unit raise {
  @fs.remove(@utf8.encode(path))
}
