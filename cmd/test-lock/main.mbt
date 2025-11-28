///|
async fn main {
  let args = @os.args()
  let mut path = None
  let mut stdin = false
  loop args[1:] {
    ["--stdin", .. args] => {
      stdin = true
      continue args
    }
    [p, .. args] => {
      path = Some(p)
      continue args
    }
    [] => break
  }
  guard path is Some(path) else {
    println("usage: test-lock <file-path> [--sleep-forever]")
    @os.exit(1)
  }
  let file = @fs.open(path, mode=ReadWrite)
  @fsx.lock_file(file) catch {
    error => {
      println("failed to lock file: \{error}")
      @os.exit(1)
    }
  }
  @stdio.stdout.write(b"locked\n")
  if stdin {
    @stdio.stdin.read_some() |> ignore()
  }
}
