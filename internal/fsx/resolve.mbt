///|
/// Resolve `path` to its absolute canonical path.
///
/// This follows symbolic links and resolves `.` and `..` segments using
/// the underlying `@fs.realpath` implementation.
pub async fn resolve(path : StringView) -> String {
  @fs.realpath(path.to_string())
}
