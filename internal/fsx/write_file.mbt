///|
/// Write raw bytes to a file, creating or truncating it.
///
/// The file is created with permission `0o644` and truncated before
/// writing when it already exists.
pub async fn write_bytes_to_file(path : StringView, content : Bytes) -> Unit {
  @fs.write_file(path.to_string(), content, create=0o644, truncate=true)
}

///|
/// Write UTF-8 text to a file at `path`.
///
/// This is a convenience wrapper around `write_bytes_to_file` that
/// encodes the provided string as UTF-8.
pub async fn write_to_file(path : StringView, content : StringView) -> Unit {
  write_bytes_to_file(path, @encoding/utf8.encode(content))
}
