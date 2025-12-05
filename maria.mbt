///|
pub struct Maria {
  logger : @pino.Logger
  agent : @agent.Agent
}

///|
#as_free_fn
pub async fn Maria::new(
  logger? : @pino.Logger = @pino.logger(
    "maria",
    try! @pino.Transport::parse("file:.moonagent/log.jsonl"),
  ),
  model~ : @model.Model,
  cwd? : String,
  user_message? : String,
  web_search? : Bool = false,
) -> Maria {
  let cwd = match cwd {
    Some(cwd) => cwd
    None => @os.cwd()
  }
  let system_prompt = [
    @prompt.prelude, @prompt.moonbit, @todo.prompt, @search_files.prompt,
  ].join("\n")
  let agent = @agent.new(
    model,
    logger~,
    cwd~,
    system_message=system_prompt,
    user_message?,
    web_search~,
  )
  let job_manager = @job.Manager::new(cwd=agent.cwd)
  let file_manager = @file.manager(cwd~)
  let todo_list = @todo.new(
    uuid=agent.uuid,
    cwd=agent.cwd,
    event_target=agent.event_target,
  )
  agent.add_tools([
    @execute_command.new(job_manager).to_agent_tool(),
    @list_files.new(file_manager).to_agent_tool(),
    @read_file.new(file_manager).to_agent_tool(),
    @todo.new_tool(todo_list).to_agent_tool(),
    @search_files.new(agent.cwd).to_agent_tool(),
    @meta_write_to_file.new(agent).to_agent_tool(),
  ])
  { logger, agent }
}

///|
pub fn Maria::close(self : Maria) -> Unit {
  self.agent.close()
}

///|
pub async fn Maria::start(self : Maria, prompt? : String) -> Unit {
  if prompt is Some(prompt) {
    let user_message = @ai.user_message(content=prompt)
    self.agent.queue_message(user_message) |> ignore()
  }
  self.agent.start()
}
