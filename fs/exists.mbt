///|
pub async fn exists(path : StringView) -> Bool {
  @fs.exists(@encoding/utf8.encode(path))
}
