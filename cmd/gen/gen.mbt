///|
pub async fn gen(input : StringView) -> Unit {
  @backtrace.initialize()
  let cwd = @os.cwd()
  let api_key = if @os.getenv("OPENROUTER_API_KEY") is Some(key) {
    key
  } else if @os.getenv("OPENAI_API_KEY") is Some(key) {
    key
  } else {
    fail(
      "Environment variable OPENROUTER_API_KEY or OPENAI_API_KEY is required",
    )
  }
  let model = @model.new(
    api_key~,
    base_url="https://openrouter.ai/api/v1",
    name="anthropic/claude-sonnet-4",
    safe_zone_tokens=200000,
  )
  let logger = @pino.logger("main", @pino.transport("file:.moonagent/log"))
  let agent = @agent.new(model, cwd~)
  defer agent.close()
  agent.add_listener(TokenCounted, context => {
    guard context.origin_token_count is Some(origin_token_count) else { return }
    guard context.pruned_token_count is Some(pruned_token_count) else { return }
    if origin_token_count != pruned_token_count {
      logger.info("Context pruned", {
        "origin_token_count": origin_token_count.to_json(),
        "pruned_token_count": pruned_token_count.to_json(),
      })
    } else {
      logger.info("Token count", { "token_count": origin_token_count.to_json() })
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
    println("> Tool result: \{result.output.to_json().stringify(indent=2)}")
    logger.info("Tool result", { "output": result.output.to_json() })
    if result.error is Some(error) {
      println("> Tool error: \{error}")
      logger.error("Tool error", { "error": error.to_json() })
    }
  })
  agent.add_listener(ConversationStart, _ => logger.info(
    "Conversation started",
    {},
  ))
  agent.add_listener(ConversationEnd, _ => logger.info("Conversation ended", {}))
  agent.add_tool(
    @execute_command.execute_command,
    @execute_command.context(cwd=agent.cwd),
  )
  let file_manager = @file.manager(cwd~)
  agent.add_tool(@list_files.list_files, file_manager)
  agent.add_tool(@read_file.read_file, file_manager)
  agent.add_tool(@write_to_file.write_to_file, file_manager)
  let todo_list = @todo.list(uuid=agent.uuid, cwd=agent.cwd)
  agent.add_tool(@todo_read.todo_read, todo_list)
  agent.add_tool(@todo_write.todo_write, todo_list)
  agent.add_tool(@search_files.search_files, agent.cwd)
  agent.add_tool(@get_moonbit_mbti.get_moonbit_mbti, agent.cwd)
  agent.add_message(
    @openai.system_message(
      content=[
        @prompt.Prelude,
        @prompt.MoonBit,
        @todo_read.Prompt,
        @todo_write.Prompt,
        @search_files.Prompt,
      ].join("\n"),
    ),
  )
  agent.add_message(@openai.user_message(content=input))
  agent.start()
}
