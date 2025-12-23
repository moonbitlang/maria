///|
pub struct QueuedMessage {
  id : @uuid.Uuid
  message : @ai.Message
  web_search : Bool
}

///|
pub impl ToJson for QueuedMessage with to_json(self : QueuedMessage) -> Json {
  {
    "id": self.id.to_string(),
    "message": self.message.to_openai().to_json(),
    "web_search": self.web_search,
  }
}

///|
/// Represents an AI agent that interacts with language models and executes tools.
///
/// The `Agent` struct encapsulates the complete state and behavior of an AI agent,
/// including conversation history, available tools, model configuration, and event
/// handling. It manages the conversation loop, token counting, context pruning,
/// and tool execution.
pub(all) struct Agent {
  /// UUID generator for creating unique identifiers.
  uuid : @uuid.Generator
  /// Current working directory used as the base path for tool operations.
  cwd : String
  model : @model.Model
  logger : @pino.Logger
  priv tools : Map[String, Tool]
  /// Conversation history containing all messages exchanged.
  priv history : @conversation.Conversation
  /// Pending messages to be sent in the next API call.
  priv mut input_queue : Array[@ai.Message]
  priv pending_queue : @deque.Deque[QueuedMessage]
  event_target : @event.EventTarget
  priv token_counter : @token_counter.Counter
  /// Pruner for managing context size within token budgets.
  priv context_pruner : @context_pruner.Pruner
  priv session_manager : @conversation.Manager
  priv rules : @rules.Loader
  priv skills : @skills.Loader
  mut web_search : Bool
  /// Queue for receiving external events from the environment.
  priv external_events : @event.ExternalEventQueue
}

///|
/// Error raised when the API response contains no choices.
///
/// This error occurs when the chat completion response from the OpenAI API
/// returns an empty choices array, which indicates an unexpected API response
/// format or a failure in the model to generate a response.
priv suberror EmptyChoices

///|
/// Queues a message to be sent to the AI model in the next round of
/// conversation.
pub fn Agent::queue_message(
  agent : Agent,
  message : @ai.Message,
  web_search? : Bool = agent.web_search,
) -> @uuid.Uuid {
  let id = agent.uuid.v4()
  agent.pending_queue.push_back(QueuedMessage::{ id, message, web_search })
  agent.emit(MessageQueued(id~))
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
  agent.skills.load_and_apply(messages)
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
/// Polls all registered external event sources and handles them.
///
/// This function is called at strategic points in the conversation loop to:
/// 1. Check for user cancellation requests
/// 2. Inject immediate user messages
/// 3. Add diagnostic context from the IDE
///
/// Parameters:
///
/// * `agent` : The agent instance to poll events for.
///
/// Returns `true` if the conversation should continue, `false` if cancelled.
async fn Agent::poll_external_events(agent : Agent) -> Bool {
  let events = agent.external_events.poll()
  for event in events {
    agent.emit(event.desc, id=event.id)
    match event.desc {
      Cancelled => {
        agent.cancel()
        return false
      }
      UserMessage(msg) =>
        agent.input_queue.push(
          @ai.user_message(
            content=(
              $|[Immediate User Message]
              $|
              $|\{msg}
              $|
              $|Please address this message immediately and prioritize it over your current task.
            ),
          ),
        )
      Diagnostics(diagnostics) =>
        if !diagnostics.is_empty() {
          let rendered = diagnostics.render(limit=10, context=2, cwd=agent.cwd)
          agent.input_queue.push(
            @ai.user_message(
              content=(
                $|[IDE Diagnostics Update]
                $|
                $|The following issues were detected in the codebase:
                $|
                $|\{rendered}
                $|
                $|Please review and address these issues if relevant to your current task.
              ),
            ),
          )
        }
      _ => ()
    }
  }
  true
}

///|
fn Agent::cancel(agent : Agent) -> Unit {
  agent.input_queue.clear()
  agent.emit(@event.Cancelled)
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
    @async.with_task_group(group => {
      group.add_defer(() => agent.event_target.flush())
      // Signal the start of conversation
      agent.emit(PreConversation)
      // We need to first poll external events before starting the loop,
      // otherwise the loop will exit immediately.
      while true {
        // Poll for external events at the start of each iteration
        // This handles user cancellation, immediate messages, and diagnostics
        guard agent.poll_external_events() else { break }
        let mut web_search = agent.web_search
        // Test if the agent.input_queue is empty, if so, pop from pending_queue
        if agent.input_queue.is_empty() {
          if agent.pending_queue.pop_front() is Some(msg) {
            // For sure to happen
            agent.input_queue.push(msg.message)
            web_search = msg.web_search
            agent.emit(MessageUnqueued(id=msg.id))
            agent.emit(UserMessage(msg.message.content()))
          }
        }
        if agent.input_queue.is_empty() {
          // No messages to send, end the conversation
          break
        }
        let tools = agent.tools_desc()
        // Retrieve and clear the message queue
        // staged contains messages that need to be sent in this call
        // Build the complete message array for the API call
        // Start with conversation history, then append any queued messages
        let messages = [..agent.history.messages(), ..agent.input_queue]

        // Count tokens, prune if needed, and apply caching
        let cache_messages = agent.prepare_messages_for_request(
          messages,
          tools~,
        )

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
          AssistantMessage(
            usage=usage.map(u => @ai.Usage::from_openai(u)),
            tool_calls=message.tool_calls.map(tc => @ai.ToolCall::from_openai_tool_call(
              tc,
            )),
            message.content.unwrap_or(""),
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
          agent.input_queue.push(
            agent.execute_tool(@ai.ToolCall::from_openai_tool_call(call)),
          )
        }
      }
      // Signal the end of conversation
      agent.emit(PostConversation)
    })
  })
}

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
  external_events? : @event.ExternalEventQueue,
  history? : @conversation.Conversation,
) -> Agent {
  // FIXME:(upstream) function with error not allowed in optional expression
  let uuid = match uuid {
    Some(uuid) => uuid
    None => @uuid.generator(@rand.chacha8())
  }
  let session_manager = @conversation.Manager::new(uuid~, cwd~)
  let rules = @rules.Loader::new(cwd.to_string(), logger~)
  let event_target = @event.EventTarget::new()
  event_target.add_listener(event => logger.info("Received event", data={
    "event": event.to_json(),
  }))
  event_target.emit(ModelLoaded(name=model.name, model~))
  let history = match history {
    Some(history) => history
    None => session_manager.new_conversation(name="history")
  }
  let external_events = match external_events {
    Some(queue) => queue
    None => @event.ExternalEventQueue::new()
  }
  let skills = @skills.Loader::new(cwd=cwd.to_string(), logger~)
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
    skills,
    web_search,
    external_events,
  }
  rules.load()
  skills.load()
  agent.set_system_prompt(system_message)
  match user_message {
    Some(message) => agent.external_events.send(UserMessage(message))
    None => ()
  }
  agent
}

///|
/// Loads an existing agent from a conversation history with the specified
/// configuration.
///
/// Parameters:
///
/// * `model` : The AI model to use for generating responses and handling tool
///   calls.
/// * `history` : The existing conversation history to load into the agent.
/// * `uuid` : Optional UUID generator for creating unique identifiers. If not
///   provided, uses ChaCha8.
/// * `logger` : Optional logger instance for recording agent activities.
///   Defaults to file logger at `.moonagent/log.jsonl`.
/// * `user_message` : Optional initial user message to send immediately after
///   loading.
/// * `web_search` : Whether to enable web search functionality. Defaults to
///   `false`.
/// * `external_events` : Optional external event queue for receiving events
///   from the environment.
///
/// Returns a new `Agent` instance initialized with the provided conversation
/// history and configuration.
pub async fn load(
  model : @model.Model,
  history : @conversation.Conversation,
  uuid? : @uuid.Generator,
  logger? : @pino.Logger,
  user_message? : String,
  web_search? : Bool = false,
  external_events? : @event.ExternalEventQueue,
) -> Agent {
  new(
    model,
    uuid?,
    logger?,
    user_message?,
    cwd=history.cwd(),
    web_search~,
    history~,
    external_events?,
  )
}

///|
pub fn Agent::clear_inputs(self : Agent) -> Array[QueuedMessage] {
  self.input_queue.clear()
  let pms = []
  while self.pending_queue.pop_front() is Some(pm) {
    self.emit(MessageUnqueued(id=pm.id))
    pms.push(pm)
  }
  pms
}

///|
/// Gets the unique identifier of the agent.
///
/// Parameters:
///
/// * `agent` : The agent instance to get the identifier for.
///
/// Returns the UUID that uniquely identifies this agent instance.
pub fn Agent::id(agent : Agent) -> @uuid.Uuid {
  agent.history.id()
}
