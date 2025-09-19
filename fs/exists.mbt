///|
pub async fn exists(path : StringView) -> Bool raise {
  @fs.exists(@encoding/utf8.encode(path))
}
