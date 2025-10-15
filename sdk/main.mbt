///|
async fn load_model(home~ : String, cwd~ : String) -> @model.Model? {
  let model_loader = @model.loader(home~, cwd~)
  let api_key : String? = if @os.getenv("OPENAI_API_KEY") is Some(key) {
    Some(key)
  } else if @os.getenv("OPENROUTER_API_KEY") is Some(key) {
    Some(key)
  } else {
    None
  }
  let name : String? = if @os.getenv("MODEL_NAME") is Some(name) {
    Some(name)
  } else {
    None
  }
  model_loader.load()
  return model_loader.get_model(name?, api_key?)
}

///|
priv suberror ModelNotConfigured

///|
async fn main {
  @backtrace.initialize()
  let cwd = @os.cwd()
  let home = @os.home()
  guard load_model(home~, cwd~) is Some(model) else { raise ModelNotConfigured }
  let agent = @agent.new(model, cwd~)
  defer agent.close()
  let stdin = @io.BufferedReader::new(@pipe.stdin)
  let stdout = @io.BufferedWriter::new(@pipe.stdout)
  let messages : @aqueue.Queue[@openai.ChatCompletionMessageParam] = @aqueue.new()
  @async.with_task_group(group => {
    agent.add_listener(RequestCompleted, context => {
      guard context.message is Some(message) && message.content is Some(content) else {
        return
      }
      let response : Json = {
        "method": "maria.agent.assistant",
        "params": content,
      }
      stdout.write(@encoding/utf8.encode(response.stringify()))
    })
    agent.add_listener(PostToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      guard context.tool_call_result is Some(json) else { return }
      guard context.tool_call_result_text is Some(text) else { return }
      let response : Json = {
        "method": "maria.agent.tool_call",
        "params": {
          "tool_call": tool_call.to_json(),
          "json": json.to_json(),
          "text": text.to_json(),
        },
      }
      stdout.write(@encoding/utf8.encode(response.stringify()))
    })
    group.spawn_bg(() => while true {
      let message = messages.get()
      agent.add_message(message)
      agent.start()
    })
    group.spawn_bg(() => while true {
      let index = stdin.find("\n")
      let line = stdin.read_exactly(index)
      stdin.drop(1)
      let json = @json.parse(@encoding/utf8.decode(line))
      match json {
        { "id": id, "method": "maria.agent.add_message", "params": params, .. } => {
          let message : @openai.ChatCompletionMessageParam = @json.from_json(
            params,
          ) catch {
            error => {
              let error : Json = {
                "jsonrpc": "2.0",
                "error": {
                  "code": -32602,
                  "message": "Invalid params",
                  "data": error.to_json(),
                },
              }
              stdout.write(@encoding/utf8.encode(error.stringify()))
              continue
            }
          }
          messages.put(message)
          let response : Json = { "jsonrpc": "2.0", "id": id, "result": null }
          stdout.write(@encoding/utf8.encode(response.stringify()))
        }
        { "id": id, "method": method_, .. } => {
          let error : Json = {
            "jsonrpc": "2.0",
            "id": id,
            "error": {
              "code": -32601,
              "message": "Method not found: \{method_}",
            },
          }
          stdout.write(@encoding/utf8.encode(error.stringify()))
        }
        _ => {
          let error : Json = {
            "jsonrpc": "2.0",
            "error": { "code": -32700, "message": "Parse error" },
          }
          stdout.write(@encoding/utf8.encode(error.stringify()))
        }
      }
    })
  })
}
