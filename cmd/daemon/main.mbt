///|
async fn main {
  let args = @os.args()
  let mut port = 8090
  let mut serve = @os.cwd()
  let mut exec_path = None
  loop args[1:] {
    ["-p" | "--port", p, .. args] => {
      port = @strconv.parse_int(p)
      continue args
    }
    ["-s" | "--serve", s, .. args] => {
      serve = if @path.is_absolute(s) { s } else { @path.join(@os.cwd(), s) }
      continue args
    }
    [e, .. args] => {
      exec_path = if @path.is_absolute(e) {
        Some(e)
      } else {
        Some(@path.join(@os.cwd(), e))
      }
      continue args
    }
    [] => break
  }
  guard exec_path is Some(exec_path) else {
    fail("Expected exec path as the first argument")
  }
  if !@fsx.exists(exec_path) {
    fail("Exec path does not exist: \{exec_path}")
  }
  let exec_path = @fsx.resolve(exec_path) catch {
    error => fail("Failed to resolve exec path '\{exec_path}': \{error}")
  }
  let daemon = Daemon::new(exec_path~, port~, serve~)
  daemon.serve()
}
