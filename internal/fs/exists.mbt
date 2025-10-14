///|
pub async fn exists(path : StringView) -> Bool {
  @fs.exists(path.to_string())
}
