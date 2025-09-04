///|
struct Tool {
  description : String
  name : String
  parameters : Map[String, Json]
  f : async (Json, ToolContext) -> String raise
}

///|
fn Tool::new(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
  f : async (Json, ToolContext) -> String raise,
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
  events : @aqueue.Queue[Event]
}

///|
suberror HttpError Int

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
  for message in agent.queue {
    match message {
      User(user) => println("< (user)\n\{user.content}")
      Tool(tool) => println("< (tool)\n\{tool.content}")
      _ => ()
    }
  }
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
  let body = @encoding.decode(body)
  let json = @json.parse(body)
  guard response.code is (200..=299) else { raise HttpError(response.code) }
  let completion : @openai.ChatCompletion = @json.from_json(json)
  guard completion.choices is [choice, ..] else { raise EmptyChoices }
  let message = choice.message
  agent.history.append(agent.queue)
  agent.queue.clear()
  agent.history.push(message.to_param())
  let content = message.content.unwrap_or("")
  println("> \{content}")
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
  agent.events.put(PreToolCall(tool_call))
  let arguments = @json.parse(tool_call.function.arguments) catch {
    error =>
      return @openai.tool_message(
        content="Error parsing tool arguments: \{error}",
        tool_call_id=tool_call.id,
      )
  }
  let result = try? (tool.f)(arguments, context)
  agent.events.put(PostToolCall(tool_call, result))
  let result = match result {
    Ok(output) => output
    Err(error) => "Error executing tool: \{error}"
  }
  @openai.tool_message(content=result, tool_call_id=tool_call.id)
}

///|
fn Agent::add_tool(agent : Agent, tool : Tool) -> Unit noraise {
  agent.tools[tool.name] = tool
}

///|
async fn Agent::start(agent : Agent) -> Unit raise {
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
}

///|
fn Agent::new(model : Model, cwd~ : String) -> Agent {
  Agent::{
    history: [],
    cwd,
    model,
    tools: {},
    queue: [],
    events: @aqueue.Queue::new(),
  }
}

///|
enum Event {
  PreToolCall(@openai.ChatCompletionMessageToolCall)
  PostToolCall(@openai.ChatCompletionMessageToolCall, Result[String, Error])
}

///|
suberror UnknownCurrentDirectory

///|
fn main {
  @async.with_event_loop(group => {
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
    group.spawn_bg(() => match agent.events.get() {
      PreToolCall(tool_call) => println("PreToolCall: \{tool_call.id}")
      PostToolCall(tool_call, result) =>
        println("PostToolCall: \{tool_call.id}, Result: \{result}")
    })
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
            return "Error: 'path' parameter is required"
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
            entries.join("\n")
          } catch {
            error => "Error: \{error}"
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
