///|
pub async fn interactive(prompt? : String, model? : String) -> Unit {
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
      let rl = @readline.interface(input=@pipe.stdin, output=@pipe.stdout)
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
