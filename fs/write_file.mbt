///|
pub async fn write_bytes_to_file(
  path : @string.View,
  content : Bytes,
) -> Unit raise {
  @fs.write_file(@utf8.encode(path), content)
}

///|
pub async fn write_to_file(
  path : @string.View,
  content : @string.View,
) -> Unit raise {
  write_bytes_to_file(path, @utf8.encode(content))
}
