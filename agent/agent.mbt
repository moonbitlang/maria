///|
struct Agent {
  cwd : String
  model : @model.Model
  tools : Map[String, @tool.Tool]
  history : Array[@openai.ChatCompletionMessageParam]
  queue : Array[@openai.ChatCompletionMessageParam]
  listeners : Map[EventKind, Array[async (EventContext) -> Unit noraise]]
}

///|
priv suberror HttpError {
  HttpError(code~ : Int, body~ : String)
} derive(Show)

///|
priv suberror EmptyChoices

///|
pub fn Agent::submit(
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
pub fn Agent::add_tool(agent : Agent, tool : @tool.Tool) -> Unit noraise {
  agent.tools[tool.name] = tool
}

///|
pub async fn Agent::start(agent : Agent) -> Unit raise {
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
pub fn Agent::new(model : @model.Model, cwd~ : String) -> Agent {
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
pub fn Agent::register(
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
pub(all) enum EventKind {
  ConversationStart
  ConversationEnd
  PreToolCall
  PostToolCall
} derive(Eq, Hash)

///|
pub struct EventContext {
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
