///|
async fn generate(
  prompt_file~ : String,
  log_file~ : String,
  model? : String,
  cwd~ : String,
) -> Unit {
  if model is Some(model) {
    println("Generating for prompt file \{prompt_file} with model \{model}")
  } else {
    println("Generating for prompt file \{prompt_file} with default model")
  }
  let model = @model.load(name?=model)
  guard model is Some(model) else {
    println("No model available; please configure a model first.")
    return
  }
  let prompt = @fsx.read_file(prompt_file)
  if @fsx.exists(log_file) {
    fail("Log file \{log_file} already exists")
  }
  let logger = @pino.logger(
    "maria_test",
    try! @pino.Transport::parse("file:\{log_file}"),
  )
  let maria = @maria.Maria::new(logger~, model~, cwd~, user_message=prompt)
  maria.start() catch {
    error => {
      logger.error("MariaFailed", data={ "error": error.to_string() })
      raise error
    }
  }
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
  let mut prompt_file = None
  let mut log_file = "logs.jsonl"
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
      log_file = lf
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
  guard model is Some(model) else {
    println("Error: --model is required")
    return
  }
  generate(prompt_file~, log_file~, model~, cwd~)
}
