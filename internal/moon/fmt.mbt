///|
pub async fn format_string(content : String) -> String {
  let result = @spawn.spawn("moonfmt", ["-"], stdin=content)
  if result.status != 0 {
    fail("moonfmt failed with status \{result.status}:\n\{result.stderr}")
  }
  result.stdout
}
