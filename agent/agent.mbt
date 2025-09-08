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
  tool_call_result : @tool.ToolResult?
}

///|
fn EventContext::new(
  usage? : @openai.CompletionUsage,
  message? : @openai.ChatCompletionMessage,
  origin_token_count? : Int,
  pruned_token_count? : Int,
  tool_call? : @openai.ChatCompletionMessageToolCall,
  tool_call_result? : @tool.ToolResult,
) -> EventContext {
  EventContext::{
    usage,
    message,
    origin_token_count,
    pruned_token_count,
    tool_call,
    tool_call_result,
  }
}

///|
struct Agent {
  logger : @pino.Logger
  cwd : String
  model : @model.Model
  tools : Map[String, @tool.Tool]
  history : Array[@openai.ChatCompletionMessageParam]
  mut queue : Array[@openai.ChatCompletionMessageParam]
  event_target : @event.Target[Event, EventContext]
  token_counter : @token.Counter
  context_pruner : @context.Pruner
}

///|
priv suberror HttpError {
  HttpError(code~ : Int, body~ : String)
} derive(Show)

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
pub fn Agent::close(agent : Agent) -> Unit {
  agent.logger.close()
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
async fn Agent::call(agent : Agent) -> @openai.ChatCompletionMessage raise {
  let tools = []
  for name, tool in agent.tools {
    let tool = @openai.tool(
      name~,
      description=tool.description,
      parameters=tool.parameters,
    )
    tools.push(tool)
  }
  let staged = agent.queue
  agent.queue = []
  let messages = [..agent.history, ..staged]
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
  let param = @openai.chat_completion(messages~, model=agent.model.name, tools~)
  let json = param.to_json()
  agent.logger.info("http-request", { "request": json })
  let body = json.stringify()
  let body = @encoding.encode(body, encoding=UTF8)
  let (response, body) = with_retry(
    logger=agent.logger,
    backoff_multiplier=2,
    delay_ms=1000,
    max_delay_ms=16000,
    max_retries=5,
    () => @http.post(
      @encoding.encode(
        "\{agent.model.base_url}/chat/completions",
        encoding=UTF8,
      ),
      body,
      headers=[
        @http.Header(
          "Authorization",
          @encoding.encode("Bearer \{agent.model.api_key}", encoding=UTF8),
        ),
        @http.Header("Content-Type", "application/json"),
        @http.Header("Connection", "close"),
      ],
    ),
  )
  guard response.code is (200..=299) else {
    raise HttpError(
      code=response.code,
      body=@encoding.decode_lossy(body, encoding=UTF8),
    )
  }
  let body = @encoding.decode(body, encoding=UTF8)
  let json = @json.parse(body)
  let completion : @openai.ChatCompletion = @json.from_json(json)
  guard completion.choices is [choice, ..] else { raise EmptyChoices }
  let message = choice.message
  agent.emit(
    RequestCompleted,
    EventContext::new(usage?=completion.usage, message~),
  )
  agent.history.append(staged)
  agent.history.push(message.to_param())
  message
}

///|
async fn Agent::execute_tool(
  agent : Agent,
  tool_call : @openai.ChatCompletionMessageToolCall,
) -> @openai.ChatCompletionMessageParam raise {
  guard agent.tools.get(tool_call.function.name) is Some(tool) else {
    @openai.tool_message(
      content="Unknown tool: \{tool_call.function.name}",
      tool_call_id=tool_call.id,
    )
  }
  let context = @tool.ToolContext::new(cwd=agent.cwd)
  agent.emit(PreToolCall, EventContext::new(tool_call~))
  let arguments = @json.parse(tool_call.function.arguments) catch {
    error =>
      return @openai.tool_message(
        content="Error parsing tool arguments: \{error}",
        tool_call_id=tool_call.id,
      )
  }
  let result = (tool.f)(arguments, context)
  agent.emit(
    PostToolCall,
    EventContext::new(tool_call~, tool_call_result=result),
  )
  @openai.tool_message(content=result.output, tool_call_id=tool_call.id)
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
  agent.tools[tool.name] = tool
}

///|
pub async fn Agent::start(agent : Agent) -> Unit raise {
  agent.emit(ConversationStart, EventContext::new())
  while !agent.queue.is_empty() {
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
async fn[T] with_retry(
  logger~ : @pino.Logger,
  backoff_multiplier~ : Int,
  delay_ms~ : Int,
  max_delay_ms~ : Int,
  max_retries~ : Int,
  f : async () -> T raise,
) -> T raise {
  guard max_retries > 0
  let errors : Array[Error] = []
  let mut delay_ms = delay_ms
  for attempt in 0..<max_retries {
    try {
      return f()
    } catch {
      (error : Error) => {
        logger.error("attempt \{attempt}/\{max_retries} failed", {
          "error": error.to_json(),
        })
        errors.push(error)
        continue
      }
    }
    delay_ms = @cmp.minimum(delay_ms * backoff_multiplier, max_delay_ms)
  }
  raise errors.last().unwrap()
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
pub async fn new(model : @model.Model, cwd~ : String) -> Agent raise {
  Agent::{
    logger: @pino.logger(@pino.transport("file:.moonagent/log")),
    history: [],
    cwd,
    model,
    tools: {},
    queue: [],
    event_target: @event.Target::new(),
    token_counter: @token.Counter::new(),
    context_pruner: @context.Pruner::new(safe_zone_tokens=model.context_window),
  }
}

///|
async fn Agent::emit(
  agent : Agent,
  kind : Event,
  context : EventContext,
) -> Unit raise {
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
  f : async (EventContext) -> Unit raise,
) -> Unit {
  agent.event_target.add_listener(kind, f)
}
