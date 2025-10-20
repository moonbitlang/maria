///|
pub(all) struct Maria {
  logger : @pino.Logger
  agent : @agent.Agent
}

///|
async fn load_model(
  home~ : String,
  cwd~ : String,
  model? : String,
) -> @model.Model? {
  let model_loader = @model.loader(home~, cwd~)
  let api_key : String? = if @os.getenv("OPENAI_API_KEY") is Some(key) {
    Some(key)
  } else if @os.getenv("OPENROUTER_API_KEY") is Some(key) {
    Some(key)
  } else {
    None
  }
  let name : String? = if model is Some(model) {
    Some(model)
  } else if @os.getenv("MODEL_NAME") is Some(name) {
    Some(name)
  } else {
    None
  }
  model_loader.load()
  return model_loader.get_model(name?, api_key?)
}

///|
pub suberror ModelNotConfigured

///|
#as_free_fn
pub async fn Maria::new(logger? : @pino.Logger, model? : String) -> Maria {
  let logger = match logger {
    Some(logger) => logger
    None => @pino.logger("maria", try! @pino.transport("file:.moonagent/log"))
  }
  let home = @os.home()
  let cwd = @os.cwd()
  guard load_model(home~, cwd~, model?) is Some(model) else {
    raise ModelNotConfigured
  }
  let agent = @agent.new(model, cwd~)
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
    guard context.message is Some(message) else { return }
    logger.info("Request completed: Usage", {
      "usage": usage.to_json(),
      "message": message.to_json(),
    })
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
    logger.info("Tool result", { "output": result.output().to_json() })
    if result is Error(error, _) {
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
    @job.Manager::new(cwd=agent.cwd),
  )
  let file_manager = @file.manager(cwd~)
  agent.add_tool(@list_files.list_files, file_manager)
  agent.add_tool(@read_file.read_file, file_manager)
  agent.add_tool(@write_to_file.write_to_file, file_manager)
  let todo_list = @todo.list(uuid=agent.uuid, cwd=agent.cwd)
  agent.add_tool(@todo_read.todo_read, todo_list)
  agent.add_tool(@todo_write.todo_write, todo_list)
  agent.add_tool(@search_files.search_files, agent.cwd)
  agent.add_message(
    @openai.system_message(
      content=[
        @prompt.prelude, @prompt.moonbit, @todo_read.prompt, @todo_write.prompt,
        @search_files.prompt,
      ].join("\n"),
    ),
  )
  Maria::{ logger, agent }
}

///|
pub fn Maria::close(self : Maria) -> Unit {
  self.agent.close()
}

///|
pub async fn Maria::start(self : Maria, prompt : String) -> Unit {
  self.agent.add_message(@openai.user_message(content=prompt))
  self.agent.start()
}
