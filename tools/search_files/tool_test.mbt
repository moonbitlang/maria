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
    let result = @search_files.search_files.call(args, taco.cwd.path())
    @json.inspect(result, content=[
      "Ok",
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
  @mock.run(t, timeout=60_000, taco => {
    guard @os.getenv("OPENAI_API_KEY") is Some(api_key) else { return }
    let _ = taco.add_file(
      "notes.txt",
      content=(
        #|These are some notes about the project.
        #|We need to implement a feature to search files.
        #|The search should be efficient and accurate.
      ),
    )
    let _ = taco.add_file(
      "file.txt",
      content=(
        #|This file contains some important information.
        #|Make sure to read it carefully.
      ),
    )
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="anthropic/claude-sonnet-4",
      safe_zone_tokens=200000,
    )
    let agent = @agent.new(model, cwd=taco.cwd.path())
    let file_manager = @file.manager(cwd=taco.cwd.path())
    agent.add_tool(@write_to_file.write_to_file, file_manager)
    agent.add_tool(@search_files.search_files, taco.cwd.path())
    agent.add_listener(PostToolCall, (event : @agent.EventContext) => taco.logger.info(
      "",
      event.to_json().as_object().unwrap_or({}),
    ))
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
