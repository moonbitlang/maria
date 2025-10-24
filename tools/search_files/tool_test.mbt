///|
async test "search_files" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "notes.txt",
      content=(
        #|These are some notes about the project.
        #|We need to implement a feature to search files.
        #|The search should be efficient and accurate.
      ),
    )
    let args : Json = { "path": ".", "regex": "search files", "kind": "regex" }
    let result = @search_files.new(taco.cwd.path()).call(args)
    @json.inspect(result.output(), content=[
      "SearchResultData",
      {
        "kind": "Regex",
        "query": "search files",
        "path": ".",
        "file_pattern": "*",
        "context_lines": 2,
        "total_matches": 1,
        "results": [
          {
            "context": "1: These are some notes about the project.\n2: We need to implement a feature to search files.\n3: The search should be efficient and accurate.",
            "line_number": 2,
            "match_line": "We need to implement a feature to search files.",
            "path": "notes.txt",
          },
        ],
        "truncated": false,
        "message": "Search completed. Found 1 matches.",
      },
    ])
  })
}

///|
async test "search_files/agentic" (t : @test.T) {
  @mock.run(t, timeout=300_000, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else {
      fail("OPENAI_API_KEY not set")
    }
    taco.add_files([
      (
        "notes.txt",
        (
          #|These are some notes about the project.
          #|We need to implement a feature to search files.
          #|The search should be efficient and accurate.
        ),
      ),
      (
        "file.txt",
        (
          #|This file contains some important information.
          #|Make sure to read it carefully.
        ),
      ),
    ])
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
          "tool_call": tool_call.to_json(),
          "tool_call_result": result.to_json(),
          "tool_call_result_text": rendered.to_json(),
        })
      _ => ()
    })
    let file_manager = @file.manager(cwd=taco.cwd.path())
    agent.add_tools([
      @write_to_file.new(file_manager).to_agent_tool(),
      @search_files.new(taco.cwd.path()).to_agent_tool(),
    ])
    agent.add_message(
      @openai.user_message(
        content=(
          $|You are an AI assistant that helps users search for text in files.
          $|The user wants to find the phrase "search files" in the project files.
          $|Use the `search_files` tool to perform the search and provide the results by writing to `results.txt`.
        ),
      ),
    )
    agent.start()
    inspect(
      @fs.read_file(@path.join(taco.cwd.path(), "results.txt")).contains(
        "notes.txt",
      ),
      content="true",
    )
  })
}
