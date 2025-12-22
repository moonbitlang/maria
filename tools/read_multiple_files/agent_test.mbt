///|
let args1 : Json = {
  "files": [
    { "path": "foo.txt", "start_line": 1, "end_line": 3 },
    { "path": "bar.txt", "start_line": 2, "end_line": 4 },
    { "path": "bar.txt" },
  ],
}

///|
let args2 : Json = { "files": [{ "path": "foo.txt" }, { "path": "bar.txt" }] }

///|
let system_prompt : String =
  $| # read_multiple_files 
  $|
  $| This tool allows you to read multiple files with specified line ranges(optional) at once 
  $| 
  $| read_multiple_files parameters: should be the typescript type `{ files : { path : string; start_line?: number; end_line?: number }[] }`
  $|
  $| ## examples 
  $|
  $| e.g. \{args1.stringify()}
  $|
  $| e.g. \{args2.stringify()}
  $|

///|
/// Test agent with read multiple files
#skip
async test "agent/read_multiple_files/specified_ranges" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    // Ask agent to create and read a file
    let content =
      #| you should concat foo.txt Line 3 - Line 4, and bar.txt Line 3,
      #| and then write to output.txt
    let model = mock.model(name=ClaudeHaiku4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      logger=mock.logger,
      system_message=system_prompt,
      user_message=content,
    )

    // Add file management tools
    let file_manager = @file.manager(cwd=mock.cwd.path())
    // Track if files were created/read
    let mut multiple_files_read = false
    agent
    ..add_tools([
      @read_multiple_files.new(file_manager).to_agent_tool(),
      @replace_in_file.new(file_manager).to_agent_tool(),
    ])
    ..add_listener(event => match event.desc {
      PreToolCall(tool_call) =>
        match tool_call.name {
          "read_multiple_files" => multiple_files_read = true
          _ => ()
        }
      _ => ()
    })
    mock.add_json_tree({
      "foo.txt": (
        #|x hgo
        #|random
        // line 3
        #|xs hello 3
        // line 4
        #| world 4
        #|foo.txt 
      ),
      "bar.txt": (
        #| a g
        #| bbbg
        // line 3
        #| random data
      ),
    })
    agent.start()
    inspect(multiple_files_read, content="true")
    // Verify file was actually created

    let file_content = @fsx.read_file(
      @pathx.join(mock.cwd.path(), "output.txt"),
    )
    inspect(
      file_content.trim(),
      content=(
        #|xs hello 3
        #| world 4
        #| random data
      ),
    )
  })
}
