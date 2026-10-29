///|
async test "search_files/agentic" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "notes.txt": (
        #|These are some notes about the project.
        #|We need to implement a feature to search files.
        #|The search should be efficient and accurate.
      ),
      "file.txt": (
        #|This file contains some important information.
        #|Make sure to read it carefully.
      ),
    })
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message=(
        $|You are an AI assistant that helps users search for text in files.
        $|The user wants to find the phrase "search files" in the project files.
        $|Use the `search_files` tool to perform the search and provide the results by writing to `results.txt`.
      ),
    )
    agent.add_listener(event => {
      match event.desc {
        PostToolCall(tool_call, result~, rendered~) =>
          mock.logger.info("PostToolCall", data={
            "tool_call": tool_call.to_openai(),
            "tool_call_result": result,
            "tool_call_result_text": rendered,
          })
        _ => ()
      }
    })
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @search_files.new(mock.cwd.path()).to_agent_tool(),
    ])
    agent.start()
    inspect(
      @fsx.read_file(Path::join(mock.cwd.path(), "results.txt").to_string()).contains(
        "notes.txt",
      ),
      content="true",
    )
  })
}
