///|
/// Check whether a file-system entry exists at `path`.
///
/// The function returns `true` if the path points to any existing entry,
/// including files, directories or symbolic links.
pub async fn exists(path : StringView) -> Bool {
  @fs.exists(path.to_string())
}
