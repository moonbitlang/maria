///|
struct Model {
  name : String
  api_key : String
  base_url : String
}

///|
fn Model::new(api_key~ : String, base_url~ : String, name~ : String) -> Model {
  Model::{ api_key, base_url, name }
}

///|
struct Agent {
  cwd : String
  model : Model
  tools : Map[String, @tool.Tool]
  history : Array[@openai.ChatCompletionMessageParam]
  queue : Array[@openai.ChatCompletionMessageParam]
  listeners : Map[EventKind, Array[async (EventContext) -> Unit noraise]]
}

///|
suberror HttpError {
  HttpError(code~ : Int, body~ : String)
} derive(Show)

///|
suberror EmptyChoices

///|
fn Agent::submit(
  agent : Agent,
  message : @openai.ChatCompletionMessageParam,
) -> Unit {
  agent.queue.push(message)
}

///|
async fn Agent::call(agent : Agent) -> @openai.ChatCompletionMessage raise {
  let tools = []
  for name, tool in agent.tools {
    tools.push(
      @openai.tool(
        name~,
        description=tool.description,
        parameters=tool.parameters,
      ),
    )
  }
  let body : Json = {
    "messages": [..agent.history, ..agent.queue].to_json(),
    "model": agent.model.name,
    "stream": false,
    "tools": tools,
  }
  let body = body.stringify()
  let body = @encoding.encode(body, encoding=UTF8)
  let (response, body) = @http.post(
    @encoding.encode("\{agent.model.base_url}/chat/completions", encoding=UTF8),
    body,
    headers=[
      @http.Header(
        "Authorization",
        @encoding.encode("Bearer \{agent.model.api_key}", encoding=UTF8),
      ),
      @http.Header("Content-Type", "application/json"),
      @http.Header("Connection", "close"),
    ],
  )
  guard response.code is (200..=299) else {
    raise HttpError(
      code=response.code,
      body=@encoding.decode_lossy(body, encoding=UTF8),
    )
  }
  let body = @encoding.decode(body)
  let json = @json.parse(body)
  let completion : @openai.ChatCompletion = @json.from_json(json)
  guard completion.choices is [choice, ..] else { raise EmptyChoices }
  let message = choice.message
  agent.history.append(agent.queue)
  agent.queue.clear()
  agent.history.push(message.to_param())
  message
}

///|
async fn Agent::execute_tool(
  agent : Agent,
  tool_call : @openai.ChatCompletionMessageToolCall,
) -> @openai.ChatCompletionMessageParam noraise {
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
fn Agent::add_tool(agent : Agent, tool : @tool.Tool) -> Unit noraise {
  agent.tools[tool.name] = tool
}

///|
async fn Agent::start(agent : Agent) -> Unit raise {
  agent.emit(ConversationStart, EventContext::new())
  while true {
    let response = agent.call()
    if response.tool_calls is [] {
      break
    }
    for i in 0..<response.tool_calls.length() {
      let call = response.tool_calls[i]
      agent.submit(agent.execute_tool(call))
    }
  }
  agent.emit(ConversationEnd, EventContext::new())
}

///|
fn Agent::new(model : Model, cwd~ : String) -> Agent {
  Agent::{ history: [], cwd, model, tools: {}, queue: [], listeners: {} }
}

///|
async fn Agent::emit(
  agent : Agent,
  kind : EventKind,
  context : EventContext,
) -> Unit noraise {
  guard agent.listeners.get(kind) is Some(listeners) else { return }
  for listener in listeners {
    listener(context)
  }
}

///|
fn Agent::register(
  agent : Agent,
  kind : EventKind,
  f : async (EventContext) -> Unit noraise,
) -> Unit {
  if agent.listeners.get(kind) is Some(listeners) {
    listeners.push(f)
  } else {
    agent.listeners[kind] = [f]
  }
}

///|
enum EventKind {
  ConversationStart
  ConversationEnd
  PreToolCall
  PostToolCall
} derive(Eq, Hash)

///|
struct EventContext {
  tool_call : @openai.ChatCompletionMessageToolCall?
  tool_call_result : @tool.ToolResult?
}

///|
fn EventContext::new(
  tool_call? : @openai.ChatCompletionMessageToolCall,
  tool_call_result? : @tool.ToolResult,
) -> EventContext {
  EventContext::{ tool_call, tool_call_result }
}

///|
suberror UnknownCurrentDirectory

///|
fn main {
  @async.with_event_loop(_ => {
    let cwd = @env.current_dir()
    guard cwd is Some(cwd) else { raise UnknownCurrentDirectory }
    let args = @sys.get_cli_args()
    if args.length() <= 1 {
      println("Usage: moonagent <prompt>")
    }
    let env = @sys.get_env_vars()
    guard env.get("OPENAI_API_KEY") is Some(api_key) else {
      println("Error: OPENAI_API_KEY environment variable not set")
    }
    let model = Model::new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="anthropic/claude-sonnet-4",
    )
    let agent = Agent::new(model, cwd~)
    agent.register(PreToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      println("Calling tool: \{tool_call.function.name}")
      try {
        let args = @json.parse(tool_call.function.arguments)
        println(args.stringify(indent=2))
      } catch {
        error => {
          println("Error parsing tool arguments: \{error}")
          println(tool_call.function.arguments)
        }
      }
    })
    agent.register(PostToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      println("Finished calling tool: \{tool_call.function.name}")
      guard context.tool_call_result is Some(result) else { return }
      println("Tool result: \{result.output}")
      if result.error is Some(error) {
        println("Tool error: \{error}")
      }
    })
    agent.register(ConversationStart, _ => println("Conversation started"))
    agent.register(ConversationEnd, _ => println("Conversation ended"))
    agent.add_tool(@tool.list_files)
    agent.add_tool(@tool.execute_command)
    let content = args[1:].join(" ")
    let message = @openai.user_message(content~)
    agent.submit(message)
    agent.start()
  }) catch {
    error => println("Error: \{error}")
  }
}
