///|
pub struct QueuedMessage {
  id : @uuid.Uuid
  message : @ai.Message
  web_search : Bool
}

///|
pub impl ToJson for QueuedMessage with to_json(self : QueuedMessage) -> Json {
  { "id": self.id.to_string(), "message": self.message.to_openai().to_json() }
}

///|
/// Represents an AI agent that interacts with language models and executes tools.
///
/// The `Agent` struct encapsulates the complete state and behavior of an AI agent,
/// including conversation history, available tools, model configuration, and event
/// handling. It manages the conversation loop, token counting, context pruning,
/// and tool execution.
///
/// Fields:
///
/// * `uuid` : UUID generator for creating unique identifiers.
/// * `cwd` : Current working directory used as the base path for tool operations.
/// * `model` : The AI model configuration and endpoint for generating responses.
/// * `logger` : Logger instance for recording agent activities and events.
/// * `tools` : Map of available tools indexed by their names.
/// * `history` : Conversation history containing all messages exchanged.
/// * `queue` : Pending messages to be sent in the next API call.
/// * `event_target` : Event dispatcher for handling agent lifecycle events.
/// * `token_counter` : Counter for tracking token usage across API calls.
/// * `context_pruner` : Pruner for managing context size within token budgets.
/// * `session_manager` : Manager for persisting and loading conversation sessions.
pub(all) struct Agent {
  uuid : @uuid.Generator
  cwd : String
  model : @model.Model
  logger : @pino.Logger
  priv tools : Map[String, Tool]
  priv mut history : @conversation.Conversation
  priv mut input_queue : Array[@ai.Message]
  priv pending_queue : @deque.Deque[QueuedMessage]
  priv event_target : @event.EventTarget
  priv token_counter : @token_counter.Counter
  priv context_pruner : @context_pruner.Pruner
  priv session_manager : @conversation.Manager
  priv rules : @rules.Loader
  mut web_search : Bool
}

///|
/// Error raised when the API response contains no choices.
///
/// This error occurs when the chat completion response from the OpenAI API
/// returns an empty choices array, which indicates an unexpected API response
/// format or a failure in the model to generate a response.
priv suberror EmptyChoices

///|
/// Adds a message to the agent's message queue for the next API call.
///
/// The message is queued and will be sent to the API in the next `call()` operation.
/// After adding the message, a `MessageAdded` event is emitted.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the message to.
/// * `message` : The chat completion message to queue for sending.
async fn Agent::add_message(agent : Agent, message : @ai.Message) -> Unit {
  agent.input_queue.push(message)
  agent.emit(MessageAdded(message))
}

///|
/// Queues a message to be sent to the AI model in the next round of
/// conversation.
pub async fn Agent::queue_message(
  agent : Agent,
  message : @ai.Message,
  web_search? : Bool = agent.web_search,
) -> @uuid.Uuid {
  let id = agent.uuid.v4()
  agent.pending_queue.push_back(QueuedMessage::{ id, message, web_search })
  agent.emit(MessageQueued(id~, message))
  id
}

///|
pub fn Agent::queued_messages(self : Agent) -> Array[QueuedMessage] {
  self.pending_queue.to_array()
}

///|
/// Closes the agent and performs any necessary cleanup.
///
/// This function is currently a placeholder for future cleanup operations
/// such as closing connections, flushing logs, or releasing resources.
///
/// Parameters:
///
/// * `agent` : The agent instance to close (currently unused).
pub fn Agent::close(_ : Agent) -> Unit {

}

///|
/// Executes a tool call requested by the AI model and returns the result.
///
/// This function handles the complete tool execution lifecycle:
/// 1. Validates that the requested tool exists
/// 2. Emits a `PreToolCall` event for logging/monitoring
/// 3. Parses and validates the tool arguments
/// 4. Executes the tool with the provided arguments
/// 5. Emits a `PostToolCall` event with the result
/// 6. Returns the result formatted as a tool message
///
/// Parameters:
///
/// * `agent` : The agent instance containing the available tools.
/// * `tool_call` : The tool call request from the AI model, containing the tool
///   name, arguments, and call ID.
///
/// Returns a `@ai.Message` containing either:
/// * The tool's successful output
/// * An error message if the tool doesn't exist, arguments are invalid, or
///   execution fails
///
/// The returned message maintains the `tool_call_id` to correlate with the
/// original request.
async fn Agent::execute_tool(
  agent : Agent,
  tool_call : @ai.ToolCall,
) -> @ai.Message {
  guard agent.tools.get(tool_call.name) is Some(tool) else {
    @ai.tool_message(
      content="Unknown tool: \{tool_call.name}",
      tool_call_id=tool_call.id,
    )
  }
  agent.emit(PreToolCall(tool_call))
  let arguments : Json = match tool_call.arguments {
    None | Some("") =>
      // when models like haiku return empty arguments, we treat it as empty object 
      {}
    Some(arguments) =>
      @json.parse(arguments) catch {
        error =>
          return @ai.tool_message(
            content="Error parsing tool arguments: \{error}, arguments: \{arguments}",
            tool_call_id=tool_call.id,
          )
      }
  }
  let (result, rendered) = match tool.call(arguments) {
    Ok((json, text)) => (Ok(json), text)
    Error(error, text) => (Err(error), text)
  }
  agent.emit(PostToolCall(tool_call, result~, rendered~))
  @ai.tool_message(content=rendered, tool_call_id=tool_call.id)
}

///|
/// Adds multiple tools to the agent's available tools collection.
///
/// This is a convenience function for adding multiple `AgentTool` instances
/// at once. Each tool is added individually and triggers a `ToolAdded` event.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tools to.
/// * `tools` : An array of `AgentTool` instances to be registered with the agent.
pub async fn Agent::add_tools(
  agent : Agent,
  tools : Array[@tool.AgentTool],
) -> Unit {
  for tool in tools {
    agent.add_agent_tool(tool)
  }
}

///|
/// Adds a single agent tool to the agent's tools collection.
///
/// The tool is indexed by its name in the agent's tool map and a `ToolAdded`
/// event is emitted for logging and monitoring purposes.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tool to.
/// * `tool` : The agent tool to register.
async fn Agent::add_agent_tool(agent : Agent, tool : @tool.AgentTool) -> Unit {
  let desc = tool.desc()
  agent.tools[desc.name] = Tool::new(tool)
  agent.emit(ToolAdded(desc))
}

///|
/// Adds a tool to the agent's available tools collection.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tool to.
/// * `tool` : The tool to be added, which will be indexed by its name for
///   future tool calls.
pub async fn[Output : ToJson + Show] Agent::add_tool(
  agent : Agent,
  tool : @tool.Tool[Output],
) -> Unit {
  agent.add_agent_tool(tool.to_agent_tool())
}

///|
/// Prepares messages for an API request by counting tokens, pruning if needed, and applying caching.
///
/// This function performs the following operations:
/// 1. Counts tokens before pruning to track context size
/// 2. Emits a `TokenCounted` event for monitoring
/// 3. Prunes messages if they exceed the safe zone token budget
/// 4. Counts tokens after pruning to verify we're within budget
/// 5. Emits a `ContextPruned` event with before/after counts
/// 6. Applies prompt caching to optimize API performance
///
/// Parameters:
///
/// * `agent` : The agent instance containing token counter and context pruner.
/// * `messages` : The message array to prepare (modified in place during pruning).
/// * `tools` : The tools array for the API call (used for token counting).
///
/// Returns the cached messages ready to be sent to the API.
async fn Agent::prepare_messages_for_request(
  agent : Agent,
  messages : Array[@ai.Message],
  tools~ : Array[@tool.ToolDesc],
) -> Array[@openai.ChatCompletionMessageParam] {
  agent.rules.apply(messages)
  let messages = messages.map(fn(msg) { msg.to_openai() })
  let tools = tools.map(x => x.to_openai())
  // Count tokens before pruning to track context size
  let origin_token_count = agent.token_counter.count_param(messages~, tools~)
  // Emit event with original token count for monitoring
  agent.emit(TokenCounted(origin_token_count))
  // Prune messages if they exceed the safe zone token budget
  // This modifies the messages array in place
  agent.context_pruner.prune_messages(messages, tools~)
  // Count tokens after pruning to verify we're within budget
  let pruned_token_count = agent.token_counter.count_param(messages~, tools~)
  // Emit event with before/after token counts (only logged if pruning occurred)
  agent.emit(ContextPruned(origin_token_count~, pruned_token_count~))
  // Apply prompt caching to messages to improve API performance
  @cache.cache_messages(messages)
}

///|
/// Starts the agent's conversation loop and executes tool calls until completion.
///
/// This function implements the main agent execution loop:
/// 1. Spawns the event target in the background to handle event processing
/// 2. Emits a `PreConversation` event to signal the start
/// 3. Repeatedly calls the AI model and executes any requested tool calls
/// 4. Continues until the model returns a response with no tool calls
/// 5. Emits a `PostConversation` event when complete
///
/// The conversation loop automatically handles:
/// * Sending queued messages to the API
/// * Processing tool call requests from the model
/// * Executing tools and returning results
/// * Managing conversation history
///
/// Parameters:
///
/// * `agent` : The agent instance to start.
///
/// The function runs within an async task group to manage concurrent operations.
pub async fn Agent::start(agent : Agent) -> Unit {
  @async.with_task_group(group => {
    // Start the event target in background to handle async event processing
    group.spawn_bg(() => agent.event_target.start(), no_wait=true)
    // Signal the start of conversation
    agent.emit(PreConversation)
    while !(agent.input_queue.is_empty() && agent.pending_queue.is_empty()) {
      let mut web_search = agent.web_search
      // Test if the agent.input_queue is empty, if so, pop from pending_queue
      if agent.input_queue.is_empty() {
        if agent.pending_queue.pop_front() is Some(msg) {
          // For sure to happen
          agent.input_queue.push(msg.message)
          web_search = msg.web_search
          agent.emit(MessageUnqueued(id=msg.id))
          agent.emit(MessageAdded(msg.message))
        }
      }

      // Build the tools array for this API call
      // Convert each registered tool into OpenAI's tool parameter format
      let tools = []
      for _, tool in agent.tools {
        if tool.enabled {
          let desc = tool.desc()
          tools.push(desc)
        }
      }
      // Retrieve and clear the message queue
      // staged contains messages that need to be sent in this call
      // Build the complete message array for the API call
      // Start with conversation history, then append any queued messages
      let messages = [
        ..agent.history.messages(include_system=true),
        ..agent.input_queue,
      ]

      // Count tokens, prune if needed, and apply caching
      let cache_messages = agent.prepare_messages_for_request(messages, tools~)

      // Enable web search plugin if configured
      let extra_body : Map[String, Json] = {}
      if web_search {
        // We only support web search plugin for OpenRouter models for now.
        //
        // FIXME: We should encode how to enable web search plugin in model
        // configuration.
        if agent.model.base_url.contains("openrouter.ai/api/v1") {
          extra_body["plugins"] = [{ "id": "web" }]
        } else {
          agent.logger.warn(
            "Web search plugin is only supported for OpenRouter models.",
          )
        }
      }

      // Make the API request to get the model's response
      let response = @openai.chat(
        model=agent.model,
        logger=agent.logger,
        @openai.chat_completion(
          messages=cache_messages,
          model=agent.model.model_name,
          tools=tools.map(x => x.to_openai()),
        ),
        extra_body~,
      )
      // Extract the message from the response, raise error if no choices returned
      guard response is { choices: [{ message, .. }, ..], usage, .. } else {
        raise EmptyChoices
      }
      let ai_message = @ai.Message::from_openai_response(message)

      // Emit event with API usage statistics and the returned message
      agent.emit(
        RequestCompleted(
          usage=usage.map(fn(u) { @ai.Usage::from_openai(u) }),
          message=ai_message,
        ),
      )

      // Add all staged messages to permanent conversation history
      agent.history.add_messages(agent.input_queue)
      agent.input_queue = []

      // Add the model's response to conversation history
      agent.history.add_message(ai_message)
      // Persist the updated conversation history to disk
      agent.session_manager.save(agent.history)
      // Execute each tool call and queue the results for the next iteration
      for call in message.tool_calls {
        agent.add_message(
          agent.execute_tool(@ai.ToolCall::from_openai_tool_call(call)),
        )
      }
    }
    // Signal the end of conversation
    agent.emit(PostConversation)
  })
}

///|
priv suberror ConversationNotFound String

///|
/// Creates a new agent instance with the specified AI model and working directory.
///
/// This function initializes a complete agent with all necessary components:
/// * Random number generator and UUID generator (or uses provided ones)
/// * Logger for recording agent activities (defaults to file logging)
/// * Conversation history manager
/// * Token counter for tracking API usage
/// * Context pruner for managing message history within token budgets
/// * Empty tool collection and message queue
/// * Event target for handling lifecycle events
///
/// Parameters:
///
/// * `model` : The AI model to use for generating responses and handling tool calls.
/// * `rand` : Optional random number generator. If not provided, uses ChaCha8.
/// * `uuid` : Optional UUID generator. If not provided, creates one using the random generator.
/// * `logger` : Optional logger instance. Defaults to file logger at `.moonagent/log.jsonl`.
/// * `cwd` : The current working directory that will be used as the base path for tool operations.
///
/// Returns a new `Agent` instance initialized with empty conversation history,
/// no tools, and a fresh event target for handling agent lifecycle events.
///
/// The agent's context pruner is configured with the model's `safe_zone_tokens`
/// setting to automatically manage conversation history size.
pub async fn new(
  model : @model.Model,
  uuid? : @uuid.Generator,
  logger? : @pino.Logger = @pino.logger(
    "agent",
    try! @pino.Transport::parse("file:.moonagent/log.jsonl"),
  ),
  system_message? : String,
  user_message? : String,
  cwd~ : StringView,
  web_search? : Bool = false,
  load_conversation? : String,
) -> Agent {
  // FIXME:(upstream) function with error not allowed in optional expression
  let uuid = match uuid {
    Some(uuid) => uuid
    None => @uuid.generator(@rand.chacha8())
  }
  let session_manager = @conversation.Manager::new(uuid~, cwd~)
  let rules = @rules.Loader::new(cwd.to_string(), logger~)
  let event_target = @event.EventTarget::new()
  event_target.emit(ModelLoaded(name=model.name, model~))
  let history = if load_conversation is Some(id) {
    guard session_manager.load(id) is Some(history) else {
      raise ConversationNotFound(id)
    }
    history
  } else {
    session_manager.new_conversation(name="history")
  }
  let agent = Agent::{
    logger,
    uuid,
    history,
    cwd: cwd.to_string(),
    model,
    tools: {},
    input_queue: [],
    pending_queue: @deque.Deque::new(),
    event_target,
    token_counter: @token_counter.Counter::new(logger~),
    context_pruner: @context_pruner.Pruner::new(
      safe_zone_tokens=model.safe_zone_tokens,
      logger~,
    ),
    session_manager,
    rules,
    web_search,
  }
  rules.load()
  if system_message is Some(system_message) {
    agent.set_system_prompt(system_message)
  }
  match user_message {
    Some(message) => agent.add_message(@ai.user_message(content=message))
    None => ()
  }
  agent
}

///|
/// Sets the system prompt for the agent's conversation history and emits an
/// event notification.
///
/// Parameters:
///
/// * `agent` : The agent instance whose system prompt will be set.
/// * `prompt` : The system prompt text to be set for the agent's conversation.
pub async fn Agent::set_system_prompt(agent : Agent, prompt : String) -> Unit {
  agent.history.set_system_prompt(prompt)
  agent.emit(MessageAdded(@ai.system_message(content=prompt)))
}

///|
/// Emits an event and logs it to the agent's logger.
///
/// This function serves as the central event dispatcher for the agent. It both
/// emits events through the event target (for registered listeners) and logs
/// them using the agent's logger for persistent recording.
///
/// Each event type is logged with appropriate structured data:
/// * `TokenCounted` - Logs the token count for the current request
/// * `ContextPruned` - Logs before/after token counts (only if pruning occurred)
/// * `PreToolCall` - Logs tool name and parsed arguments
/// * `PostToolCall` - Logs tool result or error with rendered text
/// * `PreConversation` - Logs conversation start
/// * `PostConversation` - Logs conversation end
/// * `MessageAdded` - Logs the added message
/// * `ToolAdded` - Logs tool descriptor (name, description, schema)
/// * `RequestCompleted` - Logs API usage and response message
///
/// Parameters:
///
/// * `agent` : The agent instance emitting the event.
/// * `event` : The event to emit and log.
async fn Agent::emit(agent : Agent, event : @event.Event) -> Unit {
  agent.event_target.emit(event)
  let json = event.to_json()
  guard json is Object({ "msg": String(msg), .. } as json) else {  }
  json.remove("msg")
  agent.logger.info(msg, data=json)
}

///|
/// Registers an event listener for the specified event type on the agent.
///
/// Parameters:
///
/// * `agent` : The agent to add the event listener to.
/// * `f` : The asynchronous callback function to execute when the event is
///   triggered. The function receives an `Event` containing relevant
///   event data.
pub fn Agent::add_listener(
  agent : Agent,
  f : async (@event.Event) -> Unit,
) -> Unit {
  agent.event_target.add_listener(f)
}

///|
priv struct Tool {
  mut enabled : Bool
  tool : @tool.AgentTool
}

///|
fn Tool::new(tool : @tool.AgentTool) -> Tool {
  Tool::{ enabled: true, tool }
}

///|
fn Tool::desc(self : Tool) -> @tool.ToolDesc {
  self.tool.desc()
}

///|
async fn Tool::call(
  self : Tool,
  args : Json,
) -> @tool.ToolResult[(Json, String)] noraise {
  guard self.enabled else {
    return @tool.error("Tool '\{self.tool.desc().name}' is disabled.")
  }
  self.tool.call(args)
}

///|
/// Enables or disables tools based on the provided set of tool names.
///
/// Parameters:
///
/// * `agent` : The agent instance whose tools will be enabled or disabled.
/// * `tool_names` : A set containing the names of tools that should be enabled.
///   Tools not in this set will be disabled.
pub async fn Agent::set_enabled_tools(
  agent : Agent,
  tool_names : Set[String],
) -> Unit {
  for name, tool in agent.tools {
    if tool_names.contains(name) {
      tool.enabled = true
    } else {
      tool.enabled = false
    }
  }
}

///|
/// Retrieves the unique identifier of the agent's current conversation.
///
/// Parameters:
///
/// * `self` : The agent instance to get the conversation ID from.
///
/// Returns a string representing the unique identifier of the current
/// conversation history.
pub fn Agent::conversation_id(self : Agent) -> String {
  self.history.id()
}

///|
/// Retrieves all conversation IDs managed by the agent's session manager.
///
/// Parameters:
///
/// * `self` : The agent instance to retrieve conversation IDs from.
///
/// Returns an array of strings, where each string is a unique identifier for a
/// conversation that has been persisted by the session manager.
pub async fn Agent::conversation_ids(self : Agent) -> Array[String] {
  self.session_manager.list()
}

///|
/// Loads a conversation with the specified ID and sets it as the agent's
/// current conversation history.
///
/// Parameters:
///
/// * `agent` : The agent instance whose conversation history will be replaced.
/// * `id` : The unique identifier of the conversation to load.
///
/// Throws an error of type `ConversationNotFound` if no conversation with the
/// specified ID exists.
pub async fn Agent::load_conversation(agent : Agent, id : String) -> Unit {
  guard agent.session_manager.load(id) is Some(history) else {
    raise ConversationNotFound(id)
  }
  agent.history = history
}
