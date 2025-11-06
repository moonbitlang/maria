///|
pub struct Agent {
  rand : @random.Rand
  uuid : @uuid.Generator
  cwd : String
  model : @model.Model
  logger : @pino.Logger
  priv tools : Map[String, @tool.AgentTool]
  priv history : @conversation.Conversation
  priv mut queue : Array[@openai.ChatCompletionMessageParam]
  priv event_target : EventTarget
  priv token_counter : @token.Counter
  priv context_pruner : @context.Pruner
  priv session_manager : @conversation.Manager
}

///|
priv suberror EmptyChoices

///|
pub async fn Agent::add_message(
  agent : Agent,
  message : @openai.ChatCompletionMessageParam,
) -> Unit {
  agent.queue.push(message)
  agent.emit(MessageAdded(message))
}

///|
pub fn Agent::close(_ : Agent) -> Unit {

}

///|
/// Sends a chat completion request to the OpenAI API and processes the
/// response.
///
/// Parameters:
///
/// * `agent` : The agent instance containing the model configuration,
///   conversation history, and available tools.
///
/// Returns a `@openai.ChatCompletionMessage` containing the AI model's
/// response.
///
/// Throws an error of type `HttpError` if the HTTP request fails or returns a
/// non-2xx status code, or an error of type `EmptyChoices` if the API response
/// contains no choices.
async fn Agent::call(agent : Agent) -> @openai.ChatCompletionMessage {
  let tools = []
  for name, tool in agent.tools {
    let desc = tool.desc()
    tools.push(
      @openai.tool(
        name~,
        description=desc.description,
        parameters=desc.schema.to_json(),
      ),
    )
  }
  let staged = agent.queue
  agent.queue = []
  let messages = agent.history.to_param()
  messages.append(staged)
  let origin_token_count = agent.token_counter.count_param(
    @openai.chat_completion(
      messages~,
      model=agent.model.name,
      tools~,
      usage=@openai.usage(include_=true),
    ),
  )
  agent.emit(TokenCounted(origin_token_count))
  let messages = agent.context_pruner.prune_messages(messages, tools~)
  let pruned_token_count = agent.token_counter.count_param(
    @openai.chat_completion(
      messages~,
      model=agent.model.name,
      tools~,
      usage=@openai.usage(include_=true),
    ),
  )
  agent.emit(ContextPruned(origin_token_count~, pruned_token_count~))
  let messages = @cache.cache_messages(messages)
  // make a request

  let response = @openai.chat(
    model=agent.model,
    logger=agent.logger,
    @openai.chat_completion(messages~, model=agent.model.name, tools~),
  )
  guard response.choices is [choice, ..] else { raise EmptyChoices }
  let message = choice.message
  agent.emit(RequestCompleted(usage=response.usage, message~))
  for message in staged {
    agent.history.add_message(message)
  }
  agent.history.add_message(message.to_param())
  agent.session_manager.save(agent.history)
  message
}

///|
async fn Agent::execute_tool(
  agent : Agent,
  tool_call : @openai.ChatCompletionMessageToolCall,
) -> @openai.ChatCompletionMessageParam {
  guard agent.tools.get(tool_call.function.name) is Some(tool) else {
    @openai.tool_message(
      content="Unknown tool: \{tool_call.function.name}",
      tool_call_id=tool_call.id,
    )
  }
  agent.emit(PreToolCall(tool_call))
  let arguments = @json.parse(tool_call.function.arguments) catch {
    error =>
      return @openai.tool_message(
        content="Error parsing tool arguments: \{error}",
        tool_call_id=tool_call.id,
      )
  }
  let (result, rendered) = match tool.call(arguments) {
    Ok((json, text)) => (Ok(json), text)
    Error(error, text) => (Err(error), text)
  }
  agent.emit(PostToolCall(tool_call, result~, rendered~))
  @openai.tool_message(content=rendered, tool_call_id=tool_call.id)
}

///|
pub async fn Agent::add_tools(
  agent : Agent,
  tools : Array[@tool.AgentTool],
) -> Unit {
  for tool in tools {
    agent.add_agent_tool(tool)
  }
}

///|
async fn Agent::add_agent_tool(agent : Agent, tool : @tool.AgentTool) -> Unit {
  let desc = tool.desc()
  agent.tools[desc.name] = tool
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
pub async fn Agent::start(agent : Agent) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => agent.event_target.start(), no_wait=true)
    agent.emit(PreConversation)
    while true {
      let response = agent.call()
      if response.tool_calls is [] {
        break
      }
      for call in response.tool_calls {
        agent.add_message(agent.execute_tool(call))
      }
    }
    agent.emit(PostConversation)
  })
}

///|
/// Creates a new agent instance with the specified AI model and working
/// directory.
///
/// Parameters:
///
/// * `model` : The AI model to use for generating responses and handling tool
///   calls.
/// * `cwd` : The current working directory that will be used as the base path
///   for tool operations.
///
/// Returns a new `Agent` instance initialized with empty conversation history,
/// no tools, and a fresh event target for handling agent lifecycle events.
pub async fn new(
  model : @model.Model,
  rand? : @random.Rand,
  uuid? : @uuid.Generator,
  logger? : @pino.Logger = @pino.logger(
    "agent",
    try! @pino.transport("file:.moonagent/log"),
  ),
  cwd~ : StringView,
) -> Agent {
  // FIXME:(upstream) function with error not allowed in optional expression
  let rand = match rand {
    Some(rand) => rand
    None => @rand.chacha8()
  }
  let uuid = match uuid {
    Some(uuid) => uuid
    None => @uuid.generator(rand)
  }
  let session_manager = {
    let path = cwd |> @path.join(".moonagent") |> @path.join("conversations")
    @conversation.Manager::new(uuid~, cwd=path)
  }
  let agent = Agent::{
    logger,
    rand,
    uuid,
    history: session_manager.new_conversation(name="history"),
    cwd: cwd.to_string(),
    model,
    tools: {},
    queue: [],
    event_target: EventTarget::new(),
    token_counter: @token.Counter::new(),
    context_pruner: @context.Pruner::new(
      safe_zone_tokens=model.safe_zone_tokens,
    ),
    session_manager,
  }
  agent
}

///|
async fn Agent::emit(agent : Agent, event : Event) -> Unit {
  agent.event_target.emit(event)
  match event {
    TokenCounted(token_count) =>
      agent.logger.info("TokenCounted", { "token_count": token_count.to_json() })
    ContextPruned(origin_token_count~, pruned_token_count~) =>
      agent.logger.info("ContextPruned", {
        "origin_token_count": origin_token_count.to_json(),
        "pruned_token_count": pruned_token_count.to_json(),
      })
    PreToolCall(tool_call) =>
      try {
        let args = @json.parse(tool_call.function.arguments)
        agent.logger.info("PreToolCall", {
          "tool_call": tool_call.to_json(),
          "name": tool_call.function.name.to_json(),
          "args": args,
        })
      } catch {
        error =>
          agent.logger.info("PreToolCall", {
            "tool_call": tool_call.to_json(),
            "name": tool_call.function.name.to_json(),
            "args": tool_call.function.arguments.to_json(),
            "error": error.to_json(),
          })
      }
    PostToolCall(tool_call, result~, rendered~) =>
      match result {
        Ok(output) =>
          agent.logger.info("PostToolCall", {
            "tool_call": tool_call.to_json(),
            "name": tool_call.function.name.to_json(),
            "result": output.to_json(),
            "text": rendered.to_json(),
          })
        Err(error) =>
          agent.logger.info("PostToolCall", {
            "tool_call": tool_call.to_json(),
            "name": tool_call.function.name.to_json(),
            "error": error.to_json(),
            "text": rendered.to_json(),
          })
      }
    PreConversation => agent.logger.info("PreConversation", {})
    PostConversation => agent.logger.info("PostConversation", {})
    MessageAdded(message) =>
      agent.logger.info("MessageAdded", { "message": message.to_json() })
    ToolAdded(tool_desc) =>
      agent.logger.info("ToolAdded", {
        "tool": {
          "name": tool_desc.name,
          "description": tool_desc.description,
          "schema": tool_desc.schema.to_json(),
        },
      })
    RequestCompleted(usage~, message~) =>
      agent.logger.info("RequestCompleted", {
        "usage": usage.to_json(),
        "message": message.to_json(),
      })
  }
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
pub fn Agent::add_listener(agent : Agent, f : async (Event) -> Unit) -> Unit {
  agent.event_target.add_listener(f)
}
