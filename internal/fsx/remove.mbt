///|
/// Remove the file-system entry at `path`.
///
/// This delegates to `@fs.remove` and will raise on failure according to
/// the underlying implementation.
pub async fn remove(path : StringView) -> Unit {
  @fs.remove(path.to_string())
}
