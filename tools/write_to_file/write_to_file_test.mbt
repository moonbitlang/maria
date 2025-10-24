///|
async test "write_to_file/create" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let args : Json = { "path": "nonexistent.txt" }
    let result = @write_to_file.new(manager).call(args)
    @json.inspect(result, content=[
      "Ok",
      {
        "path": "nonexistent.txt",
        "operation": "created",
        "bytes_written": 0,
        "search_used": false,
        "message": "New file created and content written to nonexistent.txt",
        "content": "",
      },
    ])
  })
}

///|
async test "write_to_file/replace" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let _ = taco.add_file("file.txt", content="Old content")
    @json.inspect(@read_file.new(manager).call({ "path": "file.txt" }), content=[
      "Ok",
      {
        "path": "file.txt",
        "content": "Old content",
        "start_line": 1,
        "end_line": 1,
      },
    ])
    let args : Json = {
      "path": "file.txt",
      "search": "Old content",
      "replace": "New content",
    }
    let result = @write_to_file.new(manager).call(args)
    @json.inspect(result, content=[
      "Ok",
      {
        "path": "file.txt",
        "operation": "updated",
        "bytes_written": 11,
        "search_used": true,
        "message": "Changes applied to file.txt",
        "content": "New content",
      },
    ])
  })
}

///|
async test "write_to_file/fail-to-match" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let _ = taco.add_file("file.txt", content="Old content")
    let args : Json = {
      "path": "file.txt",
      "search": "Non-matching content",
      "replace": "New content",
    }
    let result = @write_to_file.new(manager).call(args)
    @json.inspect(result, content=[
      "Error",
      [
        "ToolFailure", "Search content not found in file (tried all matching strategies): Non-matching content",
      ],
      "Search content not found in file (tried all matching strategies): Non-matching content",
    ])
  })
}

///|
async test "write_to_file/search-replace" (t : @test.T) {
  @mock.run(t, taco => {
    let manager = @file.manager(cwd=taco.cwd.path())
    let _ = taco.add_file(
      "file.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let args : Json = {
      "path": "file.txt",
      "search": "line 2",
      "replace": "line 2 modified",
    }
    let result = @write_to_file.new(manager).call(args)
    @json.inspect(result, content=[
      "Ok",
      {
        "path": "file.txt",
        "operation": "updated",
        "bytes_written": 36,
        "search_used": true,
        "message": "Changes applied to file.txt",
        "content": "line 1\nline 2 modified\nline 3\nline 4",
      },
    ])
  })
}

///|
async test "write_to_file/agentic" (t : @test.T) {
  // TODO: add retries support
  @mock.run(timeout=60_000, retry=3, t, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    let manager = @file.manager(cwd=taco.cwd.path())
    let file = taco.add_file(
      "file.txt",
      content=(
        #|line 1
        #|line 2
        #|line 3
        #|line 4
      ),
    )
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="qwen/qwen3-coder-plus",
      safe_zone_tokens=200000,
    )
    let agent = @agent.new(model, cwd=taco.cwd.path())
    agent.add_listener(event => match event {
      PostToolCall(tool_call, result~, rendered~) =>
        taco.logger.info("PostToolCall", {
          "name": tool_call.function.name.to_json(),
          "output": result.to_json(),
          "text": rendered.to_json(),
        })
      _ => ()
    })
    agent.add_tools([@write_to_file.new(manager)])
    agent.add_message(
      @openai.user_message(
        content="Update line 2 in file.txt to say 'line 2 modified via agent'.",
      ),
    )
    agent.start()
    inspect(
      file.read(),
      content=(
        #|line 1
        #|line 2 modified via agent
        #|line 3
        #|line 4
      ),
    )
  })
}

///|
/// does not make sense to test render separately as it's just returning the error message
// async test "write_to_file/render" {
//   @json.inspect(
//     (@write_to_file.new("").render)(@tool.error("Some error occurred")),
//     content="Some error occurred",
//   )
// }
