///|
async fn @pipe.PipeWrite::writeln(self : @pipe.PipeWrite, str : String) -> Unit {
  self.write(str + "\n")
}

///|
pub async fn execute(prompt~ : String, model? : String) -> Unit {
  try {
    let maria = @maria.Maria::new(model?)
    maria.agent.add_listener(event => match event {
      PreConversation => {
        let response : Json = {
          "method": "maria.agent.conversation_start",
          "params": {},
        }
        @pipe.stdout.writeln(response.stringify())
      }
      RequestCompleted(usage~, message~) => {
        let response : Json = {
          "method": "maria.agent.request_completed",
          "params": { "usage": usage.to_json(), "message": message.to_json() },
        }
        @pipe.stdout.writeln(response.stringify())
      }
      PostToolCall(tool_call, result~, rendered~) => {
        let response : Json = {
          "method": "maria.agent.post_tool_call",
          "params": {
            "tool_call": tool_call.to_json(),
            "json": result.to_json(),
            "text": rendered.to_json(),
          },
        }
        @pipe.stdout.writeln(response.stringify())
      }
      _ => ()
    })
    maria.start(prompt)
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
