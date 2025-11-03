///|
priv enum Destination {
  File(String)
  Directory(String)
}

///|
async fn main {
  @backtrace.initialize()
  let args = @os.args()
  guard args is [_, .. args] else {
    println(
      "Usage: test --prompt-file <prompt-file> [--log-file <log-file>|--log-dir <log-dir>]",
    )
    return
  }
  let cwd = @os.cwd()
  let mut prompt_file = None
  let mut destination = None
  let mut model = None
  loop args {
    ["--prompt-file", pf, .. args] => {
      if pf is ['-', ..] {
        println("Error: --prompt-file takes a file path")
        return
      }
      prompt_file = Some(pf)
      continue args
    }
    ["--log-file", lf, .. args] => {
      if destination is None {
        destination = Some(Destination::File(lf))
      } else {
        println("Error: Only one of --log-file or --log-dir can be specified")
        return
      }
      continue args
    }
    ["--log-dir", ld, .. args] => {
      if destination is None {
        destination = Some(Destination::Directory(ld))
      } else {
        println("Error: Only one of --log-file or --log-dir can be specified")
        return
      }
      continue args
    }
    ["--model", m, .. args] => {
      model = Some(m)
      continue args
    }
    [unknown, ..] => {
      println("Error: Unknown option: \{unknown}")
      return
    }
    [] => ()
  }
  guard prompt_file is Some(prompt_file) else {
    println("Error: --prompt-file is required")
    return
  }
  let prompt = @fs.read_file(prompt_file) catch { error => @errortrace.reraise(error) }
  let clock = @clock.epoch
  let timestamp = @time.unix(clock.now() / 1000)
    .to_plain_date_time()
    .to_string()
  let destination = match destination {
    Some(dest) => dest
    None => Destination::Directory(@path.join("logs", timestamp))
  }
  let (log_file, gen_dir) = match destination {
    File(file) => (file, @path.stem(file))
    Directory(dir) => (@path.join(dir, "log.jsonl"), @path.join(dir, "cwd"))
  }
  let log_file_exists = @fs.exists(log_file) catch { error => @errortrace.reraise(error) }
  if log_file_exists {
    fail("Log file \{log_file} already exists")
  }
  let gen_dir_exists = @fs.exists(gen_dir) catch { error => @errortrace.reraise(error) }
  if gen_dir_exists {
    fail("Generated directory \{gen_dir} already exists")
  }
  let logger = @pino.logger(
    "maria_test",
    try! @pino.transport("file:\{log_file}"),
  )
  @fs.with_temporary_directory("maria-test-XXXXXXX", tmpdir => {
    println("Running test in temporary directory: \{tmpdir}")
    let maria = @maria.Maria::new(logger~, model?, cwd=tmpdir)
    maria.start(prompt)
    let status = @spawn.spawn("cp", ["-r", tmpdir, gen_dir], cwd~)
    if status != 0 {
      fail("Failed to copy generated files from \{tmpdir} to \{gen_dir}")
    }
  }) catch { error => @errortrace.reraise(error) }
}
