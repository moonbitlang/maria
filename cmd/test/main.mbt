///|
async fn generate(
  prompt_file~ : String,
  log_dir~ : String,
  model? : String,
  cwd~ : String,
) -> Unit {
  if model is Some(model) {
    println("Generating for prompt file \{prompt_file} with model \{model}")
  } else {
    println("Generating for prompt file \{prompt_file} with default model")
  }
  let prompt = @fsx.read_file(prompt_file)
  let log_file = @pathx.join(log_dir, "log.jsonl")
  let gen_dir = @pathx.join(log_dir, "cwd")
  if @fsx.exists(log_file) {
    fail("Log file \{log_file} already exists")
  }
  if @fsx.exists(gen_dir) {
    fail("Generated directory \{gen_dir} already exists")
  }
  let logger = @pino.logger(
    "maria_test",
    try! @pino.Transport::parse("file:\{log_file}"),
  )
  let model = @model.load(name?=model)
  guard model is Some(model) else {
    println("No model available; please configure a model first.")
    return
  }
  // FIXME: Use event target if it is refactored into a generic type.
  logger.info("Received event", data={
    "event": ModelLoaded(name=model.name, model~),
  })
  @fsx.with_temporary_directory("maria-test-XXXXXXX", tmpdir => {
    println("Running test in temporary directory: \{tmpdir}")
    @async.with_task_group(group => {
      group.add_defer(() => @async.protect_from_cancel(() => {
        let result = @spawn.spawn("cp", ["-R", tmpdir, gen_dir], cwd~)
        if result.status != 0 {
          println(
            "Failed to copy generated files from \{tmpdir} to \{gen_dir}, giving up",
          )
        }
      }))
      let maria = @maria.Maria::new(
        logger~,
        model~,
        cwd=tmpdir,
        user_message=prompt,
      )
      // FIXME: Use event target if it is refactored into a generic type.
      logger.info("Received event", data={
        "event": SystemPromptSet(maria.agent.system_prompt().unwrap_or("")),
      })
      maria.agent.add_listener(event => logger.info("Received event", data={
        "event": event,
      }))
      maria.start() catch {
        error => {
          logger.error("MariaFailed", data={ "error": error.to_string() })
          raise error
        }
      }
    })
  })
}

///|
fn @time.PlainDateTime::to_dash_t_format(time : @time.PlainDateTime) -> String {
  fn last_two_digits(number : Int) -> String {
    (number % 100).to_string().pad_start(2, '0')
  }

  let year = last_two_digits(time.year())
  let month = last_two_digits(time.month())
  let day = last_two_digits(time.day())
  let hour = last_two_digits(time.hour())
  let minute = last_two_digits(time.minute())
  let second = last_two_digits(time.second())
  "\{year}-\{month}-\{day}T\{hour}-\{minute}-\{second}"
}

///|
async fn main {
  @backtrace.initialize()
  let args = @os.args()
  guard args is [_, .. args] else {
    println(
      "Usage: test [--prompt-file <prompt-file>|--prompt-dir <prompt-dir>] [--log-dir <log-dir>]",
    )
    return
  }
  let cwd = @os.cwd()
  let prompt_files = []
  let mut log_dir = "logs"
  let models = []
  loop args {
    ["--prompt-file", pf, .. args] => {
      if pf is ['-', ..] {
        println("Error: --prompt-file takes a file path")
        return
      }
      prompt_files.push(pf)
      continue args
    }
    ["--prompt-dir", pd, .. args] => {
      for entry in @fsx.list_directory(pd) {
        if entry.kind is Regular {
          prompt_files.push(entry.path)
        }
      }
      continue args
    }
    ["--log-dir", ld, .. args] => {
      log_dir = ld
      continue args
    }
    ["--model" | "--models", ms, .. args] => {
      for m in ms.split(",") {
        models.push(m.to_string())
      }
      continue args
    }
    [unknown, ..] => {
      println("Error: Unknown option: \{unknown}")
      return
    }
    [] => ()
  }
  let clock = @clock.epoch
  let timestamp = @time.unix(clock.now() / 1000)
    .to_plain_date_time()
    .to_dash_t_format()
  guard prompt_files.length() > 0 else {
    println("Error: --prompt-file/--prompt-dir is required")
    return
  }
  @async.with_task_group(group => for prompt_file in prompt_files {
    let name = @pathx.stem(@pathx.basename(prompt_file))
    for model in models {
      let log_dir = log_dir
        |> @pathx.join("\{timestamp}-\{@pathx.basename(model)}-\{name}")
      let log_dir = @pathx.join(cwd, log_dir)
      @fsx.make_directory(log_dir, recursive=true, exists_ok=true)
      group.spawn_bg(
        () => generate(prompt_file~, log_dir~, model~, cwd~),
        allow_failure=true,
      )
    }
  })
}
