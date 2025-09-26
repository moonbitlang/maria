///|
pub async fn write_bytes_to_file(path : StringView, content : Bytes) -> Unit {
  @fs.write_file(path.to_string(), content, create=0o644, truncate=true)
}

///|
pub async fn write_to_file(path : StringView, content : StringView) -> Unit {
  write_bytes_to_file(path, @encoding/utf8.encode(content))
}
