///|
pub async fn write_bytes_to_file(
  path : StringView,
  content : Bytes,
) -> Unit raise {
  @fs.write_file(@encoding/utf8.encode(path), content, create=0o644, truncate=true)
}

///|
pub async fn write_to_file(
  path : StringView,
  content : StringView,
) -> Unit raise {
  write_bytes_to_file(path, @encoding/utf8.encode(content))
}
