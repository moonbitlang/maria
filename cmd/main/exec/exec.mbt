///|
priv struct ExecOptions {
  prompt_file : String
  log_file : String
  model : String
}

///|
fn ExecOptions::parse(args : ArrayView[String]) -> ExecOptions raise {
  let mut prompt_file : String? = None
  let mut log_file : String = "logs.jsonl"
  let mut model : String? = None
  loop args {
    ["--prompt-file", pf, .. rest] => {
      if pf is ['-', ..] {
        raise @argument.InvalidArgument(
          "--prompt-file requires a file path, got '\{pf}'",
        )
      }
      prompt_file = Some(pf)
      continue rest
    }
    ["--log-file", lf, .. rest] => {
      log_file = lf
      continue rest
    }
    ["--model" | "-m", m, .. rest] => {
      model = Some(m)
      continue rest
    }
    [unknown, ..] => raise @argument.InvalidArgument(unknown)
    [] => break
  }
  guard prompt_file is Some(prompt_file) else {
    raise @argument.InvalidArgument("--prompt-file is required")
  }
  guard model is Some(model) else {
    raise @argument.InvalidArgument("--model is required")
  }
  ExecOptions::{ prompt_file, log_file, model }
}

///|
async fn ExecOptions::run(self : ExecOptions, cwd~ : String) -> Unit {
  println("Executing prompt from \{self.prompt_file} with model \{self.model}")
  let model = @model.load(name=self.model)
  guard model is Some(model) else {
    println("No model available; please configure a model first.")
    return
  }
  let prompt = @fsx.read_file(self.prompt_file)
  if @fsx.exists(self.log_file) {
    fail("Log file \{self.log_file} already exists")
  }
  let logger = @pino.logger(
    "maria_exec",
    try! @pino.Transport::parse("file:\{self.log_file}"),
  )
  let maria = @maria.Maria::new(logger~, model~, cwd~, user_message=prompt)
  maria.start() catch {
    error => {
      logger.error("ExecFailed", data={ "error": error.to_string() })
      raise error
    }
  }
}

///|
pub async fn exec(args : ArrayView[String]) -> Unit {
  let options = ExecOptions::parse(args)
  let cwd = @os.cwd()
  options.run(cwd~)
}
