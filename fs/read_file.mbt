///|
pub async fn read_file_to_bytes(path : StringView) -> Bytes {
  @fs.read_file(@encoding/utf8.encode(path))
}

///|
pub async fn read_file(path : StringView) -> String {
  let bytes = read_file_to_bytes(path)
  @encoding/utf8.decode(bytes)
}
