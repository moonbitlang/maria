///|
pub async fn read_file(path : StringView) -> String {
  @fs.read_file(path.to_string()).text()
}
