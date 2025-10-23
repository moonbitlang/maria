///|
/// Event type that occurs during agent conversation lifecycle.
pub enum Event {
  PreConversation
  PostConversation
  MessageAdded(@openai.ChatCompletionMessageParam)
  PreToolCall(@openai.ChatCompletionMessageToolCall)
  PostToolCall(
    @openai.ChatCompletionMessageToolCall,
    result~ : @tool.Result,
    rendered~ : String
  )
  TokenCounted(Int)
  ContextPruned(origin_token_count~ : Int, pruned_token_count~ : Int)
  RequestCompleted(
    usage~ : @openai.CompletionUsage?,
    message~ : @openai.ChatCompletionMessage
  )
}

///|
priv struct EventTarget {
  queue : @aqueue.Queue[Event]
  listeners : Array[async (Event) -> Unit]
}

///|
fn EventTarget::new() -> EventTarget {
  EventTarget::{ queue: @aqueue.Queue::new(), listeners: [] }
}

///|
fn EventTarget::emit(self : EventTarget, event : Event) -> Unit {
  self.queue.put(event)
}

///|
fn EventTarget::add_listener(
  self : EventTarget,
  f : async (Event) -> Unit,
) -> Unit {
  self.listeners.push(f)
}

///|
async fn EventTarget::start(self : EventTarget) -> Unit {
  while true {
    let event = self.queue.get()
    for listener in self.listeners {
      listener(event)
    }
  }
}

///|
pub struct Agent {
  rand : @random.Rand
  uuid : @uuid.Generator
  cwd : String
  model : @model.Model
  priv logger : @pino.Logger
  priv tools : Map[String, @tool.Tool]
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
pub fn Agent::add_message(
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
    let tool = @openai.tool(
      name~,
      description=tool.desc.description,
      parameters=tool.desc.parameters,
    )
    tools.push(tool)
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
  let messages = agent.context_pruner.prune_messages(messages)
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
  let request = @openai.chat_completion(
    messages~,
    model=agent.model.name,
    tools~,
  )
  let response = @openai.chat(model=agent.model, request)
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
  let result = tool.call(arguments)
  let rendered = (tool.render)(result)
  agent.emit(PostToolCall(tool_call, result~, rendered~))
  @openai.tool_message(content=rendered, tool_call_id=tool_call.id)
}

///|
/// Adds a tool to the agent's available tools collection.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tool to.
/// * `tool` : The tool to be added, which will be indexed by its name for
///   future tool calls.
pub fn Agent::add_tool(agent : Agent, tool : @tool.Tool) -> Unit noraise {
  agent.tools[tool.desc.name] = @tool.tool(
    description=tool.desc.description,
    name=tool.desc.name,
    parameters=tool.desc.parameters,
    ToolFn((args : Json) => tool.call(args)),
    render=tool.render,
  )
}

///|
pub async fn Agent::start(agent : Agent) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => agent.event_target.start(), no_wait=true)
    group.spawn_bg(() => agent.logger.start(), no_wait=true)
    agent.emit(PreConversation)
    while true {
      let response = agent.call()
      if response.tool_calls is [] {
        break
      }
      for i in 0..<response.tool_calls.length() {
        let call = response.tool_calls[i]
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
fn Agent::emit(agent : Agent, event : Event) -> Unit {
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
      agent.logger.info("PreToolCall", {
        "name": tool_call.function.name.to_json(),
        "args": tool_call.function.arguments.to_json(),
      })
    PostToolCall(tool_call, result~, rendered~) =>
      match result {
        Ok(output) =>
          agent.logger.info("PostToolCall", {
            "name": tool_call.function.name.to_json(),
            "output": output.to_json(),
            "text": rendered.to_json(),
          })
        Error(error, output) =>
          agent.logger.info("PostToolCall", {
            "name": tool_call.function.name.to_json(),
            "output": output,
            "error": error.to_json(),
            "text": rendered.to_json(),
          })
      }
    PreConversation => agent.logger.info("PreConversation", {})
    PostConversation => agent.logger.info("PostConversation", {})
    MessageAdded(message) =>
      agent.logger.info("MessageAdded", { "message": message.to_json() })
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
