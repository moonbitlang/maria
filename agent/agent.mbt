///|
/// Event type that occurs during agent conversation lifecycle.
pub(all) enum Event {
  ConversationStart
  ConversationEnd
  PreToolCall
  PostToolCall
  TokenCounted
  RequestCompleted
} derive(Eq, Hash)

///|
pub struct EventContext {
  usage : @openai.CompletionUsage?
  message : @openai.ChatCompletionMessage?
  origin_token_count : Int?
  pruned_token_count : Int?
  tool_call : @openai.ChatCompletionMessageToolCall?
  tool_call_result : @tool.Result?
  tool_call_result_text : String?
} derive(ToJson)

///|
fn EventContext::new(
  usage? : @openai.CompletionUsage,
  message? : @openai.ChatCompletionMessage,
  origin_token_count? : Int,
  pruned_token_count? : Int,
  tool_call? : @openai.ChatCompletionMessageToolCall,
  tool_call_result? : @tool.Result,
  tool_call_result_text? : String,
) -> EventContext {
  EventContext::{
    usage,
    message,
    origin_token_count,
    pruned_token_count,
    tool_call,
    tool_call_result,
    tool_call_result_text,
  }
}

///|
pub struct Agent {
  rand : @random.Rand
  uuid : @uuid.Generator
  cwd : String
  model : @model.Model
  priv tools : Map[String, @tool.Tool[Unit]]
  priv history : @conversation.Conversation
  priv mut queue : Array[@openai.ChatCompletionMessageParam]
  priv event_target : @event.Target[Event, EventContext]
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
  let messages = agent.context_pruner.prune_messages(messages)
  let pruned_token_count = agent.token_counter.count_param(
    @openai.chat_completion(
      messages~,
      model=agent.model.name,
      tools~,
      usage=@openai.usage(include_=true),
    ),
  )
  agent.emit(
    TokenCounted,
    EventContext::new(origin_token_count~, pruned_token_count~),
  )
  let messages = @cache.cache_messages(messages)
  let request = @openai.chat_completion(
    messages~,
    model=agent.model.name,
    tools~,
  )
  let response = @ai.chat(model=agent.model, request)
  guard response.choices is [choice, ..] else { raise EmptyChoices }
  let message = choice.message
  agent.emit(
    RequestCompleted,
    EventContext::new(usage?=response.usage, message~),
  )
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
  agent.emit(PreToolCall, EventContext::new(tool_call~))
  let arguments = @json.parse(tool_call.function.arguments) catch {
    error =>
      return @openai.tool_message(
        content="Error parsing tool arguments: \{error}",
        tool_call_id=tool_call.id,
      )
  }
  let result = tool.call(arguments, ())
  let rendered = (tool.render)(result)
  agent.emit(
    PostToolCall,
    EventContext::new(
      tool_call~,
      tool_call_result=result,
      tool_call_result_text=rendered,
    ),
  )
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
pub fn[T] Agent::add_tool(
  agent : Agent,
  tool : @tool.Tool[T],
  state : T,
) -> Unit noraise {
  agent.tools[tool.desc.name] = @tool.tool(
    description=tool.desc.description,
    name=tool.desc.name,
    parameters=tool.desc.parameters,
    (args : Json, _ : Unit) => tool.call(args, state),
    render=tool.render,
  )
}

///|
pub async fn Agent::start(agent : Agent) -> Unit {
  agent.emit(ConversationStart, EventContext::new())
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
  agent.emit(ConversationEnd, EventContext::new())
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
    rand,
    uuid,
    history: session_manager.new_conversation(name="history"),
    cwd: cwd.to_string(),
    model,
    tools: {},
    queue: [],
    event_target: @event.Target::new(),
    token_counter: @token.Counter::new(),
    context_pruner: @context.Pruner::new(
      safe_zone_tokens=model.safe_zone_tokens,
    ),
    session_manager,
  }
  agent
}

///|
async fn Agent::emit(
  agent : Agent,
  kind : Event,
  context : EventContext,
) -> Unit {
  agent.event_target.emit(kind, context)
}

///|
/// Registers an event listener for the specified event type on the agent.
///
/// Parameters:
///
/// * `agent` : The agent to add the event listener to.
/// * `kind` : The type of event to listen for.
/// * `f` : The asynchronous callback function to execute when the event is
///   triggered. The function receives an `EventContext` containing relevant
///   event data.
pub fn Agent::add_listener(
  agent : Agent,
  kind : Event,
  f : async (EventContext) -> Unit,
) -> Unit {
  agent.event_target.add_listener(kind, f)
}
