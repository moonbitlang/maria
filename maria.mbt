///|
struct Tool {
  description : String
  name : String
  parameters : Json
  f : async (Json, ToolContext) -> String noraise
}

///|
fn Tool::new(
  description~ : String,
  name~ : String,
  parameters~ : Json,
  f : async (Json, ToolContext) -> String noraise,
) -> Tool {
  Tool::{ description, name, parameters, f }
}

///|
struct ToolContext {
  agent : Agent
}

///|
struct Model {
  api_key : String
  base_url : String
}

///|
fn Model::new(api_key~ : String, base_url~ : String) -> Model {
  Model::{ api_key, base_url }
}

///|
struct Agent {
  mut client : @http.Client?
  mut base_path : Bytes
  cwd : String
  model : Model
  conversation : Array[@openai.ChatCompletionMessage]
  tools : Map[String, Tool]
}

///|
suberror HttpError Int

///|
suberror EmptyChoices

///|
suberror InvalidUrl String

///|
suberror InvalidSchema @string.View

///|
async fn Agent::call(
  agent : Agent,
  messages : Array[@openai.ChatCompletionMessageParam],
) -> @openai.ChatCompletionMessage raise {
  let body : Json = {
    "messages": messages.to_json(),
    "model": "anthropic/claude-sonnet-4",
    "stream": false,
  }
  let body = body.stringify()
  let body = @encoding.encode(body, encoding=UTF8)
  let client = match agent.client {
    Some(client) => client
    None => {
      guard agent.model.base_url.split("://").collect() is [schema, host_path] else {
        raise InvalidUrl(agent.model.base_url)
      }
      let protocol = match schema {
        "https" => @http.Protocol::Https
        "http" => @http.Protocol::Http
        schema => raise InvalidSchema(schema)
      }
      let host = match host_path.split("/").collect() {
        [] => raise InvalidUrl(agent.model.base_url)
        [host] => {
          agent.base_path = "/"
          host
        }
        [host, .. path] => {
          agent.base_path = [
              '/',
              ..@encoding.encode(path.join("/"), encoding=UTF8),
            ]
          host
        }
      }
      let host = @encoding.encode(host, encoding=UTF8)
      let client = @http.Client::connect(
        host,
        headers=[
          @http.Header(
            "Authorization",
            @encoding.encode("Bearer \{agent.model.api_key}", encoding=UTF8),
          ),
          @http.Header("Content-Type", "application/json"),
        ],
        protocol~,
      )
      agent.client = Some(client)
      client
    }
  }
  let base_path = agent.base_path
  let response = client.post(base_path + "/chat/completions", Fixed(body))
  let body = client.read_all()
  let body = @encoding.decode(body)
  let json = @json.parse(body)
  guard response.code is (200..=299) else { raise HttpError(response.code) }
  let completion : @openai.ChatCompletion = @json.from_json(json)
  guard completion.choices is [choice, ..] else { raise EmptyChoices }
  choice.message
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
  let arguments = @json.parse(tool_call.function.arguments) catch {
    error =>
      return @openai.tool_message(
        content="Error parsing tool arguments: \{error}",
        tool_call_id=tool_call.id,
      )
  }
  let result = (tool.f)(arguments, context)
  @openai.tool_message(content=result, tool_call_id=tool_call.id)
}

///|
fn Agent::add_tool(agent : Agent, tool : Tool) -> Unit noraise {
  agent.tools[tool.name] = tool
}

///|
async fn Agent::loop_call(
  agent : Agent,
  messages : Array[@openai.ChatCompletionMessageParam],
) -> Unit raise {
  while true {
    let response = agent.call(messages)
    messages.clear()
    agent.conversation.push(response)
    if response.tool_calls is [] {
      break
    }
    for i in 0..<response.tool_calls.length() {
      let call = response.tool_calls[i]
      messages.push(agent.execute_tool(call))
    }
  }
}

///|
fn Agent::new(model : Model, cwd~ : String) -> Agent {
  Agent::{
    client: None,
    base_path: "/",
    conversation: [],
    cwd,
    model,
    tools: {},
  }
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
    let model = Model::new(api_key~, base_url="https://openrouter.ai/api/v1")
    let agent = Agent::new(model, cwd~)
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
    agent.loop_call([message])
  }) catch {
    error => println("Error: \{error}")
  }
}
