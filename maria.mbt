///|
pub struct Maria {
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
  let agent = @agent.new(model, logger~, cwd~)
  agent.add_listener(event => match event {
    TokenCounted(token_count) =>
      logger.info("TokenCounted", { "token_count": token_count.to_json() })
    RequestCompleted(usage~, message~) =>
      logger.info("RequestCompleted", {
        "usage": usage.to_json(),
        "message": message.to_json(),
      })
    PreToolCall(tool_call) =>
      try {
        let args = @json.parse(tool_call.function.arguments)
        logger.info("PreToolCall", {
          "name": tool_call.function.name.to_json(),
          "args": args,
        })
      } catch {
        error =>
          logger.info("PreToolCall", {
            "name": tool_call.function.name.to_json(),
            "args": tool_call.function.arguments.to_json(),
            "error": error.to_json(),
          })
      }
    PostToolCall(tool_call, result~, rendered~) =>
      match result {
        Ok(output) =>
          logger.info("PostToolCall", {
            "name": tool_call.function.name.to_json(),
            "output": output.to_json(),
            "text": rendered.to_json(),
          })
        Error(error, output) =>
          logger.info("PostToolCall", {
            "name": tool_call.function.name.to_json(),
            "output": output,
            "error": error.to_json(),
            "text": rendered.to_json(),
          })
      }
    PreConversation => logger.info("PreConversation", {})
    PostConversation => logger.info("PostConversation", {})
    _ => ()
  })
  let job_manager = @job.Manager::new(cwd=agent.cwd)
  agent.add_tool(@execute_command.new(job_manager))
  let file_manager = @file.manager(cwd~)
  agent.add_tool(@list_files.new(file_manager))
  agent.add_tool(@read_file.new(file_manager))
  agent.add_tool(@write_to_file.new(file_manager))
  let todo_list = @todo.list(uuid=agent.uuid, cwd=agent.cwd)
  agent.add_tool(@todo_read.new(todo_list))
  agent.add_tool(@todo_write.new(todo_list))
  agent.add_tool(@search_files.new(agent.cwd))
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
  let user_message = @openai.user_message(content=prompt)
  self.agent.add_message(user_message)
  self.agent.start()
}
