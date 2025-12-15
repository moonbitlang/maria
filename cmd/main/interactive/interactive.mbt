///|
async fn println(msg : String) -> Unit {
  @stdio.stdout.write("\{msg}\n")
}

///|
pub async fn interactive(args : ArrayView[String]) -> Unit {
  let mut prompt : String? = None
  let mut model : String? = None
  let mut web_search : Bool = false
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
    [unknown, ..] => raise @argument.InvalidArgument(unknown)
    [] => break
  }
  guard @model.load(name?=model) is Some(model) else {
    println("No model available; please configure a model first.")
    return
  }
  @async.with_task_group(group => {
    let maria = @maria.Maria::new(model~, web_search~)
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
    let rl = @readline.interface(input=@stdio.stdin, output=@stdio.stdout)
    group.spawn_bg(() => rl.start())
    if prompt is Some(prompt) {
      println("$ \{prompt}")
      maria.start(prompt~) catch {
        error => println("! \{error}")
      }
    }
    while true {
      rl.set_prompt("$ ")
      rl.prompt()
      let prompt = rl.read_line()
      maria.start(prompt~) catch {
        error => println("! \{error}")
      }
    }
  })
}
