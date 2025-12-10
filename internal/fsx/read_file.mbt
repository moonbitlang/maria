///|
/// Read the entire file at `path` as a UTF-8 string.
///
/// This is a small convenience wrapper around `@fs.read_file` that reads
/// all bytes from the file and decodes them as UTF-8 text.
pub async fn read_file(path : StringView) -> String {
  @fs.read_file(path.to_string()).text()
}
