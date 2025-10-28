///|
async fn main {
  @backtrace.initialize()
  let args = @os.args()
  guard args is [_, .. args] else {
    println("Usage: test --prompt-file <prompt-file> [--log-file <log-file>]")
    return
  }
  let cwd = @os.cwd()
  let mut prompt_file = None
  let mut log_file = None
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
      log_file = Some(lf)
      continue args
    }
    ["--model", m, .. args] => {
      model = Some(m)
      continue args
    }
    [unknown, ..] => {
      println("Error: Unknown argument: \{unknown}")
      return
    }
    [] => ()
  }
  guard prompt_file is Some(prompt_file) else {
    println("Error: --prompt-file is required")
    return
  }
  let prompt = @fs.read_file(prompt_file)
  let clock = @clock.epoch
  let timestamp = @time.unix(clock.now() / 1000)
    .to_plain_date_time()
    .to_string()
  let log_file = if log_file is Some(log_file) {
    log_file
  } else {
    "maria_test_\{timestamp}.jsonl"
  }
  let logger = @pino.logger(
    "maria_test",
    try! @pino.transport("file:\{log_file}"),
  )
  @fs.with_temporary_directory("maria-test-XXXXXXX", tmpdir => {
    println("Running test in temporary directory: \{tmpdir}")
    let maria = @maria.Maria::new(logger~, model?, cwd=tmpdir)
    maria.start(prompt)
    let zip_out = StringBuilder::new()
    let status = @spawn.spawn(
      "zip",
      ["-r", "maria_test_\{timestamp}.zip", tmpdir],
      stdout=zip_out,
      stderr=zip_out,
      cwd~,
    )
    if status != 0 {
      fail(
        "Failed to create zip archive of test directory (\{status}):\n\{zip_out.to_string()}",
      )
    }
  })
}
