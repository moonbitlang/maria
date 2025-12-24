///|
async fn println(msg : String) -> Unit {
  @stdio.stdout.write("\{msg}\n")
}

///|
pub async fn interactive(args : ArrayView[String]) -> Unit {
  let mut prompt : String? = None
  let mut model : String? = None
  let mut web_search : Bool = false
  let mut log_file : String? = None
  loop args {
    ["--prompt" | "-p", value, .. rest] => {
      prompt = Some(value)
      continue rest
    }
    ["--model" | "-m", value, .. rest] => {
      model = Some(value)
      continue rest
    }
    ["--web-search", .. rest] => {
      web_search = true
      continue rest
    }
    ["--log-file", value, .. rest] => {
      log_file = Some(value)
      continue rest
    }
    [unknown, ..] => raise @argument.InvalidArgument(unknown)
    [] => break
  }
  let logger = match log_file {
    Some(log_file) =>
      Some(@pino.logger("maria", @pino.Transport::file(log_file)))
    None => None
  }
  guard @model.load(name?=model) is Some(model) else {
    println("No model available; please configure a model first.")
    return
  }
  @async.with_task_group(group => {
    let maria = @maria.Maria::new(model~, web_search~, logger?)
    maria.agent.add_listener(event => match event.desc {
      AssistantMessage(content, ..) =>
        if !content.is_blank() {
          println(content)
        }
      PreToolCall(tool_call) =>
        match tool_call.arguments {
          None => println("% \{tool_call.name}")
          Some(arguments) =>
            try {
              let arguments = @json.parse(arguments)
              println("% \{tool_call.name} \{arguments.stringify(indent=2)}")
            } catch {
              _ => println("% \{tool_call.name}\n  \{arguments}")
            }
        }
      PostToolCall(_, rendered~, ..) => {
        let lines = rendered.split("\n").collect()
        for i = 0; i < lines.length(); i = i + 1 {
          let text = lines[i]
          println("> \{text}")
        }
      }
      _ => ()
    })
    async fn clear_inputs_and_prompt(
      maria : @maria.Maria,
      rl : @readline.Interface,
    ) -> Unit {
      let qms = maria.agent.clear_inputs()
      for qm in qms {
        rl.set_prompt("$ ")
        rl.set_line(@encoding/utf8.encode(qm.message.content()))
        rl.prompt()
        break
      }
    }

    let rl = @readline.interface(input=@stdio.stdin, output=@stdio.stdout)
    let mut task : @async.Task[Unit]? = None
    group.spawn_bg(() => for {
      rl.start() catch {
        @readline.CtrlC =>
          if task is Some(round) {
            round.cancel()
            clear_inputs_and_prompt(maria, rl)
          } else {
            // Clear the current input line
            println("")
            rl.set_line("")
            // Re-prompt the user
            rl.set_prompt("$ ")
            rl.prompt()
            continue
          }
        error => raise error
      }
    })
    if prompt is Some(prompt) {
      println("$ \{prompt}")
      let round = group.spawn(
        () => maria.start(prompt~) catch {
          error => {
            println("! \{error}")
            clear_inputs_and_prompt(maria, rl)
          }
        },
        allow_failure=true,
      )
      task = Some(round)
      defer {
        task = None
      }
      round.wait() catch {
        _ => ()
      }
    }
    while true {
      rl.set_prompt("$ ")
      rl.prompt()
      let prompt = rl.read_line()
      let round = group.spawn(
        () => maria.start(prompt~) catch {
          error => {
            println("! \{error}")
            clear_inputs_and_prompt(maria, rl)
          }
        },
        allow_failure=true,
      )
      task = Some(round)
      defer {
        task = None
      }
      round.wait() catch {
        _ => ()
      }
    }
  })
}
