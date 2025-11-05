///|
pub async fn run(cwd? : StringView) -> (Int, String) {
  let cwd : StringView = match cwd {
    None => @os.cwd()
    Some(cwd) =>
      if @path.is_absolute(cwd) {
        cwd
      } else {
        @path.join(@os.cwd(), cwd)
      }
  }
  let stdout = StringBuilder::new()
  let status = @spawn.spawn("moon", ["run"], stdout~, cwd~)
  (status, stdout.to_string())
}
