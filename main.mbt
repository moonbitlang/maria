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
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="anthropic/claude-sonnet-4",
      context_window=200000,
    )
    let agent = @agent.new(model, cwd~)
    agent.add_listener(TokenCounted, context => {
      guard context.origin_token_count is Some(origin_token_count) else {
        return
      }
      guard context.pruned_token_count is Some(pruned_token_count) else {
        return
      }
      if origin_token_count != pruned_token_count {
        println(
          "Context pruned from \{origin_token_count} to \{pruned_token_count} tokens",
        )
      } else {
        println("Token count: \{origin_token_count}")
      }
    })
    agent.add_listener(RequestCompleted, context => {
      guard context.usage is Some(usage) else { return }
      println("Request completed. Usage: \{usage}")
    })
    agent.add_listener(PreToolCall, context => {
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
    agent.add_listener(PostToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      println("Finished calling tool: \{tool_call.function.name}")
      guard context.tool_call_result is Some(result) else { return }
      println("Tool result: \{result.output}")
      if result.error is Some(error) {
        println("Tool error: \{error}")
      }
    })
    agent.add_listener(ConversationStart, _ => println("Conversation started"))
    agent.add_listener(ConversationEnd, _ => println("Conversation ended"))
    agent.add_tool(@tool.list_files)
    agent.add_tool(@tool.execute_command)
    let content = args[1:].join(" ")
    let message = @openai.user_message(content~)
    agent.add_message(message)
    agent.start()
  }) catch {
    error => println("Error: \{error}")
  }
}
