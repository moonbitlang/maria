///|
pub async fn remove(path : StringView) -> Unit {
  @fs.remove(path.to_string())
}
