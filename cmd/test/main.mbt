///|
async fn main {
  @backtrace.initialize()
  let args = @os.args()
  guard args is [_, .. args] else {
    println("Usage: test --prompt-file <prompt-file> [--log-file <log-file>]")
    return
  }
  let mut prompt_file = None
  let mut log_file = None
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
    "maria_test_log_\{timestamp}.jsonl"
  }
  let logger = @pino.logger(
    "maria_test",
    try! @pino.transport("file:\{log_file}"),
  )
  @async.with_task_group(group => {
    group.spawn_bg(() => logger.start(), no_wait=true)
    let maria = @maria.Maria::new(logger~)
    maria.start(prompt)
  })
}
