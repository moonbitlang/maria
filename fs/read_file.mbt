///|
pub async fn read_file_to_bytes(path : @string.View) -> Bytes raise {
  @fs.read_file(@utf8.encode(path))
}

///|
pub async fn read_file(path : @string.View) -> String raise {
  let bytes = read_file_to_bytes(path)
  @utf8.decode(bytes)
}
