///|
pub async fn format_string(content : String) -> String {
  let stderr = StringBuilder::new()
  let stdout = StringBuilder::new()
  let status = @spawn.spawn("moonfmt", ["-"], stdin=content, stdout~, stderr~)
  if status != 0 {
    fail("moonfmt failed with status \{status}:\n\{stderr.to_string()}")
  }
  stdout.to_string()
}
