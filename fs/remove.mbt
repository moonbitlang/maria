///|
pub async fn remove(path : StringView) -> Unit raise {
  @fs.remove(@encoding/utf8.encode(path))
}
