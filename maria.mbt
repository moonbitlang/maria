///|
/// Maria is the main AI coding agent that provides intelligent assistance
/// for software development tasks. It integrates various tools for file management,
/// command execution, and code analysis.
pub struct Maria {
  logger : @pino.Logger
  agent : @agent.Agent
}

///|
/// Check if the model supports apply_patch tool.
/// Only GPT 5.1+ models support this tool.
fn supports_apply_patch(model : @model.Model) -> Bool {
  let name = model.model_name.to_lower()
  if name.contains("gpt-5.1") || name.contains("gpt-5.2") {
    return true
  }
  false
}

///|
/// Creates a new Maria agent instance.
///
/// Parameters:
///
/// - logger: Optional logger for recording agent activities (defaults to file-based logger)
/// - model: The AI model to use for the agent
/// - cwd: Optional working directory (defaults to current working directory)
/// - user_message: Optional initial user message to start the conversation
/// - web_search: Whether to enable web search capabilities (defaults to false)
///
/// Returns a configured Maria instance ready to assist with coding tasks.
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
  let todo_list = @todo.new(uuid=agent.uuid, cwd=agent.cwd)
  agent.add_tools([
    @execute_command.new(job_manager).to_agent_tool(),
    @list_files.new(file_manager).to_agent_tool(),
    @read_file.new(file_manager).to_agent_tool(),
    @todo.new_tool(todo_list).to_agent_tool(),
    @search_files.new(agent.cwd).to_agent_tool(),
    @meta_write_to_file.new(agent).to_agent_tool(),
  ])
  agent.add_tool(@fix_moonbit_warnings.new(agent), enabled=false)
  // Add apply_patch tool for GPT 5.1+ models
  if supports_apply_patch(model) {
    agent.add_tool(@apply_patch.new(agent.cwd))
  }
  { logger, agent }
}

///|
/// Closes the Maria agent and releases associated resources.
/// Should be called when the agent is no longer needed (using `defer` ideally).
pub fn Maria::close(self : Maria) -> Unit {
  self.agent.close()
}

///|
/// Starts the Maria agent and begins processing tasks.
///
/// Parameters:
///
/// - prompt: Optional initial prompt to send to the agent before starting
///
/// The agent will process messages from its queue and respond to user requests,
/// and stops when there are no more messages to process.
pub async fn Maria::start(self : Maria, prompt? : String) -> Unit {
  if prompt is Some(prompt) {
    let user_message = @ai.user_message(content=prompt)
    self.agent.queue_message(user_message) |> ignore()
  }
  self.agent.start()
}
