///|
priv suberror ApiKeyNotSet

///|
impl Show for ApiKeyNotSet with output(_ : ApiKeyNotSet, logger : &Logger) -> Unit {
  logger.write_string(
    "API key not set in environment variable OPENROUTER_API_KEY",
  )
}

///|
priv enum Conversation {
  List
  Show(id~ : String, mut output~ : String?)
}

///|
priv struct Arguments {
  mut repo : String?
  mut max_while_loop : Int?
  mut conversation : Conversation?
}

///|
fn Arguments::new() -> Arguments {
  Arguments::{ repo: None, max_while_loop: None, conversation: None }
}

///|
priv suberror InvalidArgument String

///|
fn Arguments::parse(self : Arguments, args : ArrayView[String]) -> Unit raise {
  loop args[:] {
    ["--repo", repo, .. rest] => {
      self.repo = Some(repo)
      continue rest
    }
    ["--max-while-loop", arg, .. rest] => {
      let max_while_loop = @strconv.parse_int(arg) catch {
        error =>
          raise InvalidArgument(
            "--max-while-loop requires an integer argument: \{error}",
          )
      }
      if max_while_loop <= 0 {
        raise InvalidArgument(arg)
      }
      self.max_while_loop = Some(max_while_loop)
      continue rest
    }
    ["conversations", .. rest] => {
      self.conversation = Some(Conversation::List)
      continue rest
    }
    ["conversation", id, .. rest] => {
      let conversation = Conversation::Show(id~, output=None)
      self.conversation = Some(conversation)
      guard conversation is (Show(..) as conversation)
      match rest {
        ["--output", output, .. rest] => {
          conversation.output = Some(output)
          continue rest
        }
        [.. rest] => continue rest
      }
    }
    [arg, ..] => raise InvalidArgument(arg)
    [] => break
  }
}

///|
priv struct Migrator {
  repo : String
  max_while_loop : Int
}

///|
fn normalize_repo_name(name : StringView) -> String {
  let normalized = StringBuilder::new()
  for char in name {
    if char is ('a'..='z' | 'A'..='Z' | '0'..='9' | '_') {
      normalized.write_char(char)
    } else {
      normalized.write_char('_')
    }
  }
  normalized.to_string()
}

///|
fn get_repo_name(url : String) -> String {
  let name = url.split("/").collect().pop()
  match name {
    Some([.. name, .. ".git"]) => name.to_string()
    Some(name) => name.to_string()
    None => "repository"
  }
}

///|
async fn Migrator::execute(
  self : Migrator,
  model : @model.Model,
  cwd? : String,
) -> Unit {
  let cwd = cwd.unwrap_or_else(@os.cwd)
  let src_name = get_repo_name(self.repo)
  let dst_name = normalize_repo_name(src_name)
  let dst_path = @path.join(cwd, dst_name)
  let src_path = dst_path
    |> @path.join(".moonagent")
    |> @path.join("repos")
    |> @path.join(src_name)
  for loop_index in 1..=self.max_while_loop {
    if !@fs.exists(dst_path) {
      @moon.new(name=dst_name, dst_name)
    }
    if !@fs.exists(src_path) {
      println("cloning repository \{self.repo} into \{src_path}...")
      @git.clone(self.repo, to=src_path, cwd=dst_path)
    }
    println("cloned into \{src_path}")
    let agent = @agent.new(model, cwd=dst_path)
    println("created agent")
    let todo_list = @todo.list(rand=agent.rand, cwd=dst_path)
    println("created todo list")
    let file_manager = @file.manager(cwd=dst_path)
    println("created file manager")
    defer agent.close()
    let prompt =
      $|Using the reference at \{src_path}, migrate the target repository into
      $|the current MoonBit project. Translate file-by-file and preserve original
      $|structure; avoid freeform rewrites.
    agent.add_message(@openai.user_message(content=prompt))
    agent.add_tool(
      @execute_command.execute_command,
      @execute_command.context(rand=agent.rand, cwd=dst_path),
    )
    agent.add_tool(@file.list_files, file_manager)
    agent.add_tool(@file.read_file, file_manager)
    agent.add_tool(@file.write_to_file, file_manager)
    agent.add_tool(@todo.read, todo_list)
    agent.add_tool(@todo.write, todo_list)
    agent.add_tool(@fix_moonbit_warnings.fix_moonbit_warnings, agent)
    agent.add_listener(RequestCompleted, context => {
      guard context.message is Some(message) && message.content is Some(content) else {
        return
      }
      println("> \{content}")
    })
    agent.add_listener(PreToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      println("> Calling tool: \{tool_call.function.name}")
      try {
        let args = @json.parse(tool_call.function.arguments)
        println("> Tool arguments: \{args.to_json().stringify(indent=2)}")
      } catch {
        error =>
          println(
            "> Error parsing tool arguments: \{error}\nArguments: \{tool_call.function.arguments}",
          )
      }
    })
    agent.add_listener(PostToolCall, context => {
      guard context.tool_call_result is Some(result) else { return }
      println("> Tool result: \{result.output}")
      if result.error is Some(error) {
        println("> Tool error: \{error}")
      }
    })
    println("Migration attempt #\{loop_index}")
    agent.start()
  }
}

///|
async fn main {
  @async.with_task_group(group => {
    let cwd = @os.cwd()
    let api_key = if @os.getenv("OPENROUTER_API_KEY") is Some(key) {
      key
    } else if @os.getenv("OPENAI_API_KEY") is Some(key) {
      key
    } else {
      raise ApiKeyNotSet
    }
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="anthropic/claude-sonnet-4",
      context_window=200000,
    )
    let args = @os.args()
    let arguments = Arguments::new()
    arguments.parse(args[1:])
    if arguments.conversation is Some(conversation) {
      let path = cwd |> @path.join(".moonagent") |> @path.join("conversations")
      let manager = @conversation.Manager::new(path~)
      match conversation {
        List =>
          for i, id in manager.list() {
            let conversation = manager.load(id)
            guard conversation is Some(conversation) else { continue }
            let lines = ["\{i + 1}. \{id}"]
            lines.append(conversation.display().map(line => "    \{line}"))
            println(lines.join("\n"))
          }
        Show(id~, output~) => {
          let conversation = manager.load(Id(id))
          guard conversation is Some(conversation) else { return }
          if output is Some(output) {
            if output.has_suffix(".md") {
              @fs.write_to_file(output, conversation.export_to_markdown())
            }
          } else {
            let lines = conversation.display(show_messages=true)
            println(lines.join("\n"))
          }
        }
      }
      return
    }
    if arguments.repo is Some(repo) {
      let migrator = Migrator::{
        repo,
        max_while_loop: match arguments.max_while_loop {
          None => 1
          Some(max_while_loop) => max_while_loop
        },
      }
      migrator.execute(model)
      return
    }
    let logger = @pino.logger("main", @pino.transport("file:.moonagent/log"))
    let agent = @agent.new(model, cwd~)
    defer agent.close()
    agent.add_listener(TokenCounted, context => {
      guard context.origin_token_count is Some(origin_token_count) else {
        return
      }
      guard context.pruned_token_count is Some(pruned_token_count) else {
        return
      }
      if origin_token_count != pruned_token_count {
        logger.info("Context pruned", {
          "origin_token_count": origin_token_count.to_json(),
          "pruned_token_count": pruned_token_count.to_json(),
        })
      } else {
        logger.info("Token count", {
          "token_count": origin_token_count.to_json(),
        })
      }
    })
    agent.add_listener(RequestCompleted, context => {
      guard context.usage is Some(usage) else { return }
      logger.info("Request completed: Usage", { "usage": usage.to_json() })
      guard context.message is Some(message) && message.content is Some(content) else {
        return
      }
      println("> \{content}")
    })
    agent.add_listener(PreToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      logger.info("Calling tool", { "name": tool_call.function.name.to_json() })
      try {
        let args = @json.parse(tool_call.function.arguments)
        logger.info("Tool arguments", { "args": args })
      } catch {
        error =>
          logger.error("Error parsing tool arguments", {
            "error": error.to_json(),
            "arguments": tool_call.function.arguments.to_json(),
          })
      }
    })
    agent.add_listener(PostToolCall, context => {
      guard context.tool_call is Some(tool_call) else { return }
      logger.info("Finished calling tool", {
        "name": tool_call.function.name.to_json(),
      })
      guard context.tool_call_result is Some(result) else { return }
      println("> Tool result: \{result.output}")
      logger.info("Tool result", { "output": result.output.to_json() })
      if result.error is Some(error) {
        println("> Tool error: \{error}")
        logger.error("Tool error", { "error": error.to_json() })
      }
    })
    agent.add_listener(ConversationStart, _ => logger.info(
      "Conversation started",
      {},
    ))
    agent.add_listener(ConversationEnd, _ => logger.info("Conversation ended", {}))
    agent.add_tool(
      @execute_command.execute_command,
      @execute_command.context(rand=agent.rand, cwd=agent.cwd),
    )
    let file_manager = @file.manager(cwd~)
    agent.add_tool(@file.list_files, file_manager)
    agent.add_tool(@file.read_file, file_manager)
    agent.add_tool(@file.write_to_file, file_manager)
    let todo_list = @todo.list(rand=agent.rand, cwd=agent.cwd)
    agent.add_tool(@todo.read, todo_list)
    agent.add_tool(@todo.write, todo_list)
    agent.add_tool(@search_files.search_files, agent.cwd)
    agent.add_message(
      @openai.system_message(
        content=[
          @prompt.Prelude,
          @prompt.MoonBit,
          @todo.ReadPrompt,
          @todo.WritePrompt,
          @search_files.SearchFilesPrompt,
        ].join("\n"),
      ),
    )
    let rl = @readline.interface(input=@pipe.stdin, output=@pipe.stdout)
    rl.set_prompt("< ")
    group.spawn_bg(() => rl.start())
    while true {
      rl.prompt()
      let content : String = rl.read_line()
      let message = @openai.user_message(content~)
      agent.add_message(message)
      agent.start()
    }
  }) catch {
    error => println("Error: \{error}")
  }
}
