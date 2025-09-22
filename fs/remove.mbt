///|
pub async fn remove(path : StringView) -> Unit {
  @fs.remove(@encoding/utf8.encode(path))
}
