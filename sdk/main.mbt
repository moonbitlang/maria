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
async fn @pipe.PipeWrite::writeln(self : @pipe.PipeWrite, str : String) -> Unit {
  self.write(str + "\n")
}

///|
async fn main {
  try {
    @backtrace.initialize()
    let args = @os.args()
    guard args is [_, prompt] else {
      let error : Json = {
        "error": { "code": -1, "message": "Invalid arguments" },
      }
      println(error.stringify())
      return
    }
    let cwd = @os.cwd()
    let home = @os.home()
    guard load_model(home~, cwd~) is Some(model) else {
      raise ModelNotConfigured
    }
    let agent = @agent.new(model, cwd~)
    defer agent.close()
    agent.add_tool(
      @execute_command.execute_command,
      @execute_command.context(cwd~),
    )
    let file_manager = @file.manager(cwd~)
    agent.add_tool(@list_files.list_files, file_manager)
    agent.add_tool(@read_file.read_file, file_manager)
    agent.add_tool(@write_to_file.write_to_file, file_manager)
    agent.add_tool(@search_files.search_files, agent.cwd)
    let todo_list = @todo.list(uuid=agent.uuid, cwd=agent.cwd)
    agent.add_tool(@todo_read.todo_read, todo_list)
    agent.add_tool(@todo_write.todo_write, todo_list)
    agent.add_message(
      @openai.system_message(
        content=[
          @prompt.Prelude,
          @prompt.MoonBit,
          @todo_read.Prompt,
          @todo_write.Prompt,
          @search_files.Prompt,
        ].join("\n"),
      ),
    )
    agent.add_message(@openai.user_message(content=prompt))
    let stdout = @pipe.stdout
    @async.with_task_group(_ => {
      agent.add_listener(RequestCompleted, context => {
        guard context.usage is Some(usage) else { return }
        guard context.message is Some(message) else { return }
        let response : Json = {
          "method": "maria.agent.request_completed",
          "params": { "usage": usage.to_json(), "message": message.to_json() },
        }
        stdout.writeln(response.stringify())
      })
      agent.add_listener(PostToolCall, context => {
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
        stdout.writeln(response.stringify())
      })
      agent.start()
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
