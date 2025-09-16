///|
pub async fn read_file_to_bytes(path : StringView) -> Bytes raise {
  @fs.read_file(@utf8.encode(path))
}

///|
pub async fn read_file(path : StringView) -> String raise {
  let bytes = read_file_to_bytes(path)
  @utf8.decode(bytes)
}
