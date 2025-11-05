///|
priv enum Destination {
  File(String)
  Directory(String)
}

///|
async fn generate(
  prompt_file~ : String,
  destination~ : Destination,
  model? : String,
  cwd~ : String,
) -> Unit {
  if model is Some(model) {
    println("Generating for prompt file \{prompt_file} with model \{model}")
  } else {
    println("Generating for prompt file \{prompt_file} with default model")
  }
  let prompt = @fsx.read_file(prompt_file)
  let (log_file, gen_dir) = match destination {
    File(file) => (file, @path.stem(file))
    Directory(dir) => (@path.join(dir, "log.jsonl"), @path.join(dir, "cwd"))
  }
  if @fsx.exists(log_file) {
    fail("Log file \{log_file} already exists")
  }
  if @fsx.exists(gen_dir) {
    fail("Generated directory \{gen_dir} already exists")
  }
  let logger = @pino.logger(
    "maria_test",
    try! @pino.transport("file:\{log_file}"),
  )
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
      let maria = @maria.Maria::new(logger~, model?, cwd=tmpdir)
      maria.start(prompt) catch {
        error => {
          logger.error("MariaFailed", { "error": error.to_json() })
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
      "Usage: test [--prompt-file <prompt-file>|--prompt-dir <prompt-dir>] [--log-file <log-file>|--log-dir <log-dir>]",
    )
    return
  }
  let cwd = @os.cwd()
  let prompt_files = []
  let mut destination = None
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
    let name = @path.stem(@path.basename(prompt_file))
    for model in models {
      let destination = match destination {
        Some(dest) => dest
        None => {
          let dest = "logs"
            |> @path.join("\{timestamp}-\{@path.basename(model)}-\{name}")
          let dest = @path.join(cwd, dest)
          @fsx.make_directory(dest, recursive=true, exists_ok=true)
          Destination::Directory(dest)
        }
      }
      group.spawn_bg(
        () => generate(prompt_file~, destination~, model~, cwd~),
        allow_failure=true,
      )
    }
  })
}
