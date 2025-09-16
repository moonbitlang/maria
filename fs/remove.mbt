///|
pub async fn remove(path : StringView) -> Unit raise {
  @fs.remove(@utf8.encode(path))
}
