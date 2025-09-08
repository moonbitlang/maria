///|
priv suberror UnknownCurrentDirectory

///|
fn main {
  @async.with_event_loop(_ => {
    let cwd = @env.current_dir()
    guard cwd is Some(cwd) else { raise UnknownCurrentDirectory }
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
    let logger = @pino.logger(@pino.transport("file:.moonagent/log"))
    let agent = @agent.new(model, cwd~)
    defer agent.close()
    agent.add_listener(TokenCounted, context => {
      guard context.origin_token_count is Some(origin_token_count) else {
        return
      }
      guard context.pruned_token_count is Some(pruned_token_count) else {
        return
      }
      if origin_token_count != pruned_token_count {
        logger.info("Context pruned", {
          "origin_token_count": origin_token_count.to_json(),
          "pruned_token_count": pruned_token_count.to_json(),
        })
      } else {
        logger.info("Token count", {
          "token_count": origin_token_count.to_json(),
        })
      }
    })
    agent.add_listener(RequestCompleted, context => {
      guard context.usage is Some(usage) else { return }
      logger.info("Request completed: Usage", { "usage": usage.to_json() })
      guard context.message is Some(message) && message.content is Some(content) else {
        return
      }
      println("> \{content}")
    })
    agent.add_listener(PreToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      logger.info("Calling tool", { "name": tool_call.function.name.to_json() })
      try {
        let args = @json.parse(tool_call.function.arguments)
        logger.info("Tool arguments", { "args": args })
      } catch {
        error =>
          logger.error("Error parsing tool arguments", {
            "error": error.to_json(),
            "arguments": tool_call.function.arguments.to_json(),
          })
      }
    })
    agent.add_listener(PostToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      logger.info("Finished calling tool", {
        "name": tool_call.function.name.to_json(),
      })
      guard context.tool_call_result is Some(result) else { return }
      logger.info("Tool result", { "output": result.output.to_json() })
      if result.error is Some(error) {
        logger.error("Tool error", { "error": error.to_json() })
      }
    })
    agent.add_listener(ConversationStart, _ => logger.info(
      "Conversation started",
      {},
    ))
    agent.add_listener(ConversationEnd, _ => logger.info("Conversation ended", {}))
    agent.add_tool(@tool.list_files)
    agent.add_tool(@tool.execute_command)
    while true {
      let content = @readline.readline("< ")
      let message = @openai.user_message(content~)
      agent.add_message(message)
      agent.start()
    }
  }) catch {
    error => println("Error: \{error}")
  }
}
