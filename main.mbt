///|
struct Tool {
  description : String
  name : String
  parameters : Map[String, Json]
  f : async (Json, ToolContext) -> ToolResult noraise
}

///|
struct ToolResult {
  output : String
  error : Error?
}

///|
fn ToolResult::ok(output : String) -> ToolResult {
  ToolResult::{ output, error: None }
}

///|
fn ToolResult::error(output : String) -> ToolResult {
  ToolResult::{ output, error: Some(Failure(output)) }
}

///|
fn ToolResult::new(output : String, error? : Error) -> ToolResult {
  ToolResult::{ output, error }
}

///|
fn Tool::new(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
  f : async (Json, ToolContext) -> ToolResult noraise,
) -> Tool {
  Tool::{ description, name, parameters, f }
}

///|
struct ToolContext {
  agent : Agent
}

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
  tools : Map[String, Tool]
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
  let context = ToolContext::{ agent, }
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
fn Agent::add_tool(agent : Agent, tool : Tool) -> Unit noraise {
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
  tool_call_result : ToolResult?
}

///|
fn EventContext::new(
  tool_call? : @openai.ChatCompletionMessageToolCall,
  tool_call_result? : ToolResult,
) -> EventContext {
  EventContext::{ tool_call, tool_call_result }
}

///|
suberror UnknownCurrentDirectory

///|
suberror TimeoutError {
  TimeoutError(command~ : String, arguments~ : Array[String], timeout~ : Int)
}

///|
pub fn TimeoutError::new(
  command~ : String,
  arguments~ : Array[String],
  timeout~ : Int,
) -> TimeoutError {
  TimeoutError(command~, arguments~, timeout~)
}

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
    agent.add_tool(
      Tool::new(
        description="List files in a directory",
        name="list_files",
        parameters={
          "type": "object",
          "properties": {
            "path": {
              "type": "string",
              "description": "The path to list files from, relative to the current working directory",
            },
          },
          "required": ["path"],
        },
        (args, context) => {
          guard args is { "path": String(path), .. } else {
            return ToolResult::error("Error: 'path' parameter is required")
          }
          try {
            let path = @encoding.encode(
              context.agent.cwd + "/" + path,
              encoding=UTF8,
            )
            let dir = @fs.opendir(path)
            defer dir.close()
            let entries = []
            for
              entry in dir.read_all(include_special=false, include_hidden=false) {
              let entry = path + "/" + entry
              let file = @fs.open(entry, mode=ReadOnly)
              defer file.close()
              let entry = match file.kind() {
                Directory => entry + "/"
                _ => entry
              }
              entries.push(@encoding.decode(entry))
            }
            ToolResult::ok(entries.join("\n"))
          } catch {
            error => ToolResult::new("Error listing files: \{error}", error~)
          }
        },
      ),
    )
    agent.add_tool(
      Tool::new(
        description="Execute a shell command",
        name="execute_command",
        parameters={
          "type": "object",
          "properties": {
            "command": {
              "type": "string",
              "description": "The shell command to execute",
            },
            "arguments": {
              "type": "array",
              "items": { "type": "string" },
              "description": "The arguments to pass to the command",
              "default": [],
            },
            "timeout": {
              "type": "number",
              "description": "The timeout in seconds for the command to execute",
              "default": 10,
            },
          },
          "required": ["command", "arguments", "timeout"],
        },
        (args, context) => {
          guard args
            is {
              "command": String(command),
              "arguments": arguments,
              "timeout": Number(timeout, ..),
              ..
            } else {
            return ToolResult::error(
              "Error: 'command', 'arguments' and 'timeout' parameters are required",
            )
          }
          let arguments : Array[String] = @json.from_json(arguments) catch {
            error =>
              return ToolResult::error("Error parsing 'arguments': \{error}")
          }
          let timeout = (timeout * 1000).to_int()
          try {
            let result = @async.with_timeout_opt(timeout, () => {
              let cmd = @encoding.encode(command, encoding=UTF8)
              let args = arguments.map(arg => @encoding.encode(
                arg,
                encoding=UTF8,
              ))
              let output = @pipe.pipe()
              let cwd = @encoding.encode(context.agent.cwd, encoding=UTF8)
              let status = @process.run(
                cmd,
                args,
                stdout=output.1,
                stderr=output.1,
                cwd~,
              )
              let output = output.0.read_all()
                |> @encoding.decode(encoding=UTF8)
              return "Exit code: \{status}\nOutput:\n\{output}"
            })
            match result {
              Some(result) => ToolResult::ok(result)
              None => raise TimeoutError(command~, arguments~, timeout~)
            }
          } catch {
            error =>
              ToolResult::new("Error executing command: \{error}", error~)
          }
        },
      ),
    )
    let content = args[1:].join(" ")
    let message = @openai.user_message(content~)
    agent.submit(message)
    agent.start()
  }) catch {
    error => println("Error: \{error}")
  }
}
