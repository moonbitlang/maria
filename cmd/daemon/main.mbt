///|
pub async fn start(args : ArrayView[String]) -> Unit {
  let mut port = 8090
  let mut serve = @os.cwd()
  let mut exec_path = None
  loop args {
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
  let exec_path = if exec_path is Some(exec_path) {
    exec_path
  } else {
    @os.executable()
  }
  let daemon = Daemon::new(exec_path~, port~, serve~)
  daemon.serve()
}
