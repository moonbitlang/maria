///|
pub(all) struct Maria {
  logger : @pino.Logger
  agent : @agent.Agent
}

///|
pub suberror ModelNotConfigured

///|
#as_free_fn
pub async fn Maria::new(
  logger? : @pino.Logger = @pino.logger(
    "maria",
    try! @pino.transport("file:.moonagent/log"),
  ),
  model? : String,
  cwd? : String,
) -> Maria {
  let home = @os.home()
  let cwd = match cwd {
    None => @os.cwd()
    Some(cwd) => cwd
  }
  guard @model.load_model(home~, cwd~, model?) is Some(model) else {
    raise ModelNotConfigured
  }
  let agent = @agent.new(model, cwd~)
  agent.add_listener(TokenCounted, context => {
    guard context
      is {
        origin_token_count: Some(origin_token_count),
        pruned_token_count: Some(pruned_token_count),
        ..,
      } else {
      return
    }
    logger.info("TokenCounted", { "token_count": origin_token_count.to_json() })
    if origin_token_count != pruned_token_count {
      logger.info("ContextPruned", {
        "origin_token_count": origin_token_count.to_json(),
        "pruned_token_count": pruned_token_count.to_json(),
      })
    }
  })
  agent.add_listener(RequestCompleted, context => {
    guard context.usage is Some(usage) else { return }
    guard context.message is Some(message) else { return }
    logger.info("RequestCompleted", {
      "usage": usage.to_json(),
      "message": message.to_json(),
    })
  })
  agent.add_listener(PreToolCall, context => {
    guard context.tool_call is Some(tool_call) else { return }
    try {
      let args = @json.parse(tool_call.function.arguments)
      logger.info("PreToolCall", {
        "name": tool_call.function.name.to_json(),
        "args": args,
      })
    } catch {
      error =>
        logger.error("PreToolCall", {
          "name": tool_call.function.name.to_json(),
          "args": tool_call.function.arguments.to_json(),
          "error": error.to_json(),
        })
    }
  })
  agent.add_listener(PostToolCall, context => {
    guard context.tool_call is Some(tool_call) else { return }
    guard context.tool_call_result is Some(result) else { return }
    guard context.tool_call_result_text is Some(text) else { return }
    match result {
      Error(error, output) => {
        logger.info("PostToolCall", {
          "name": tool_call.function.name.to_json(),
          "output": output,
          "error": error.to_json(),
          "text": text.to_json(),
        })
        logger.error("Tool error", { "error": error.to_json() })
      }
      Ok(output) =>
        logger.info("PostToolCall", {
          "name": tool_call.function.name.to_json(),
          "output": output,
          "text": text.to_json(),
        })
    }
  })
  agent.add_listener(ConversationStart, _ => logger.info("PreConversation", {}))
  agent.add_listener(ConversationEnd, _ => logger.info("PostConversation", {}))
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
  let system_prompt = [
    @prompt.prelude, @prompt.moonbit, @todo_read.prompt, @todo_write.prompt, @search_files.prompt,
  ].join("\n")
  let system_message = @openai.system_message(content=system_prompt)
  agent.add_message(system_message)
  Maria::{ logger, agent }
}

///|
pub fn Maria::close(self : Maria) -> Unit {
  self.agent.close()
}

///|
pub async fn Maria::start(self : Maria, prompt : String) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.logger.start(), no_wait=true)
    let user_message = @openai.user_message(content=prompt)
    // TODO: move to event system
    self.logger.info("MessageAdded", { "message": user_message.to_json() })
    self.agent.add_message(user_message)
    self.agent.start()
  })
}
