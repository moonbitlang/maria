///|
async fn @pipe.PipeWrite::writeln(self : @pipe.PipeWrite, str : String) -> Unit {
  self.write(str + "\n")
}

///|
pub async fn execute(args : ArrayView[String]) -> Unit {
  try {
    guard args is [prompt] else {
      let error : Json = {
        "error": { "code": -1, "message": "Invalid arguments" },
      }
      println(error.stringify())
      return
    }
    let maria = @maria.Maria::new()
    @async.with_task_group(_ => {
      maria.agent.add_listener(RequestCompleted, context => {
        guard context.usage is Some(usage) else { return }
        guard context.message is Some(message) else { return }
        let response : Json = {
          "method": "maria.agent.request_completed",
          "params": { "usage": usage.to_json(), "message": message.to_json() },
        }
        @pipe.stdout.writeln(response.stringify())
      })
      maria.agent.add_listener(PostToolCall, context => {
        guard context.tool_call is Some(tool_call) else { return }
        guard context.tool_call_result is Some(json) else { return }
        guard context.tool_call_result_text is Some(text) else { return }
        let response : Json = {
          "method": "maria.agent.post_tool_call",
          "params": {
            "tool_call": tool_call.to_json(),
            "json": json.to_json(),
            "text": text.to_json(),
          },
        }
        @pipe.stdout.writeln(response.stringify())
      })
      maria.start(prompt)
    })
  } catch {
    @io.ReaderClosed => ()
    error => {
      let error : Json = {
        "error": { "code": -1, "message": error.to_string() },
      }
      println(error.stringify())
    }
  }
}
