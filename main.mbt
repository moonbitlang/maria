///|
suberror UnknownCurrentDirectory

///|
fn main {
  @async.with_event_loop(_ => {
    let cwd = @env.current_dir()
    guard cwd is Some(cwd) else { raise UnknownCurrentDirectory }
    let args = @sys.get_cli_args()
    if args.length() <= 1 {
      println("Usage: moonagent <prompt>")
    }
    let env = @sys.get_env_vars()
    guard env.get("OPENAI_API_KEY") is Some(api_key) else {
      println("Error: OPENAI_API_KEY environment variable not set")
    }
    let model = @model.Model::new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="anthropic/claude-sonnet-4",
    )
    let agent = @agent.Agent::new(model, cwd~)
    agent.register(PreToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      println("Calling tool: \{tool_call.function.name}")
      try {
        let args = @json.parse(tool_call.function.arguments)
        println(args.stringify(indent=2))
      } catch {
        error => {
          println("Error parsing tool arguments: \{error}")
          println(tool_call.function.arguments)
        }
      }
    })
    agent.register(PostToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      println("Finished calling tool: \{tool_call.function.name}")
      guard context.tool_call_result is Some(result) else { return }
      println("Tool result: \{result.output}")
      if result.error is Some(error) {
        println("Tool error: \{error}")
      }
    })
    agent.register(ConversationStart, _ => println("Conversation started"))
    agent.register(ConversationEnd, _ => println("Conversation ended"))
    agent.add_tool(@tool.list_files)
    agent.add_tool(@tool.execute_command)
    let content = args[1:].join(" ")
    let message = @openai.user_message(content~)
    agent.submit(message)
    agent.start()
  }) catch {
    error => println("Error: \{error}")
  }
}
