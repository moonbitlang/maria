///|
pub async fn interactive(args : ArrayView[String]) -> Unit {
  let mut prompt : String? = None
  let mut model : String? = None
  loop args {
    ["--prompt" | "-p", value, .. rest] => {
      prompt = Some(value)
      continue rest
    }
    ["--model" | "-m", value, .. rest] => {
      model = Some(value)
      continue rest
    }
    [unknown, ..] => raise @argument.InvalidArgument(unknown)
    [] => break
  }
  @async.with_task_group(group => {
    let maria = @maria.Maria::new(model?)
    maria.agent.add_listener(event => match event {
      RequestCompleted(message~, ..) => {
        guard message.content is Some(content) else { return }
        println(content)
      }
      PreToolCall(tool_call) =>
        try {
          let arguments = @json.parse(tool_call.function.arguments)
          println(
            "% \{tool_call.function.name} \{arguments.stringify(indent=2)}",
          )
        } catch {
          _ =>
            println(
              "% \{tool_call.function.name}\n  \{tool_call.function.arguments}",
            )
        }
      PostToolCall(_, rendered~, ..) =>
        rendered.split("\n").each(text => println("> \{text}"))
      _ => ()
    })
    if prompt is Some(prompt) {
      maria.start(prompt)
    } else {
      let rl = @readline.interface(input=@stdio.stdin, output=@stdio.stdout)
      rl.set_prompt("$ ")
      group.spawn_bg(() => rl.start())
      while true {
        rl.prompt()
        let content : String = rl.read_line()
        maria.start(content)
      }
    }
  })
}
