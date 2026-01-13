///|
/// Maria is the main AI coding agent that provides intelligent assistance
/// for software development tasks. It integrates various tools for file management,
/// command execution, and code analysis.
pub struct Maria {
  logger : @pino.Logger
  agent : @agent.Agent
}

///|
fn setup_agent(agent : @agent.Agent, cwd~ : String) -> Unit {
  let job_manager = @job.Manager::new(cwd=agent.cwd)
  let file_manager = @file.manager(cwd~)
  let todo_list = @todo.new(uuid=agent.uuid, cwd=agent.cwd)
  agent.add_tools([
    @execute_command.new(job_manager).to_agent_tool(),
    @list_files.new(file_manager).to_agent_tool(),
    @read_file.new(file_manager).to_agent_tool(),
    @todo.new_tool(todo_list).to_agent_tool(),
    @search_files.new(agent.cwd).to_agent_tool(),
    @write_to_file.new(agent.cwd).to_agent_tool(),
  ])
  agent.add_tool(@fix_moonbit_warnings.new(agent), enabled=false)
  // GPT 5.1+ uses apply_patch only, other models use meta_write_to_file
  if agent.model.supports_apply_patch {
    agent.add_tool(@apply_patch.new(agent.cwd))
  } else {
    agent.add_tool(@meta_write_to_file.new(agent))
    agent.add_tool(@replace_in_file.new(file_manager))
  }
}

///|
/// Creates a new Maria agent instance.
///
/// Parameters:
/// - logger: Optional logger for recording agent activities (defaults to file-based logger)
/// - model: The AI model to use for the agent
/// - cwd: Optional working directory (defaults to current working directory)
/// - user_message: Optional initial user message to start the conversation
/// - web_search: Whether to enable web search capabilities (defaults to false)
///
/// Returns a configured Maria instance ready to assist with coding tasks.
#as_free_fn
pub async fn Maria::new(
  name? : String,
  logger? : @pino.Logger = @pino.logger(
    "maria",
    try! @pino.Transport::parse("file:.moonagent/log.jsonl"),
  ),
  model~ : @model.Model,
  home? : String,
  cwd? : String,
  user_message? : String,
  web_search? : Bool = false,
) -> Maria {
  let cwd = match cwd {
    Some(cwd) => cwd
    None => @os.cwd()
  }
  let system_prompt = [@prompt.prelude, @todo.prompt, @search_files.prompt].join(
    "\n",
  )
  let agent = @agent.new(
    name?,
    model,
    logger~,
    home?=home.map(home => home),
    cwd~,
    system_message=system_prompt,
    user_message?,
    web_search~,
  )
  setup_agent(agent, cwd~)
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

///|
/// Resumes a previously saved Maria agent session.
///
/// Parameters:
/// - logger: Optional logger for recording agent activities (defaults to file-based logger)
/// - model: The AI model to use for the agent
/// - cwd: Optional working directory (defaults to current working directory)
/// - id: The unique identifier of the conversation to resume
/// - user_message: Optional user message to add to the resumed conversation
/// - web_search: Whether to enable web search capabilities (defaults to false)
///
/// Returns a Maria instance with the conversation history restored.
/// Fails if the conversation with the given id cannot be found.
#as_free_fn
pub async fn Maria::resume_(
  logger? : @pino.Logger = @pino.logger(
    "maria",
    try! @pino.Transport::parse("file:.moonagent/log.jsonl"),
  ),
  model~ : @model.Model,
  home? : String,
  id : @uuid.Uuid,
  user_message? : String,
  web_search? : Bool,
) -> Maria {
  let home = match home {
    Some(home) => home
    None => @os.home()
  }
  let uuid = @uuid.generator(@rand.chacha8())
  let session_manager = @conversation.Manager::new(home~, uuid~)
  guard session_manager.load(id) is Some(conversation) else {
    fail("Conversation with id '\{id}' not found.")
  }
  // Use the conversation's web_search setting if not explicitly overridden.
  let web_search = web_search.unwrap_or(conversation.web_search())
  let agent = @agent.load(
    model,
    conversation,
    logger~,
    user_message?,
    web_search~,
  )
  setup_agent(agent, cwd=conversation.cwd())
  { logger, agent }
}
