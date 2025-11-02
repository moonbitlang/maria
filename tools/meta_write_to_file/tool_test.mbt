///|
async test "create-file" (t : @test.T) {
  @mock.run(t, mock => {
    let model = @model.open_router_model(api_key="")
    // this tool requires agent to fix syntax errors, but the direct call just works
    // so the agent is not running
    mock.add_files([
      (
        "moon.mod.json",
        Json::object({ "name": "example", "version": "0.1.0" }).stringify(
          indent=2,
        ),
      ),
      ("moon.pkg.json", Json::object({ "is-main": true }).stringify(indent=2)),
    ])
    let agent = @agent.new(model, logger=mock.logger, cwd=mock.cwd.path())
    let tool = @meta_write_to_file.new(agent)
    agent.add_tool(tool)
    let result = @tool.call(tool, {
      "path": "main.mbt",
      "replace": (
        #|///|
        #|fn main {
        #|  println("Hello, MoonBit!")
        #|}
      ),
      "description": "Create a main function that prints 'Hello, MoonBit!' to the console.",
    })
    inspect(
      mock.show(result),
      content=(
        #|Path: (mock:cwd)/main.mbt
        #|Message: File written and formatted successfully to main.mbt
        #|Diff: 
        #|
        #|**Changes made during formatting:**
        #|```diff
        #|diff --git original modified
        #|index 8258f5d..c8bbf10 100644
        #|--- original
        #|+++ modified
        #|@@ -1,4 +1,4 @@
        #| ///|
        #| fn main {
        #|   println("Hello, MoonBit!")
        #|-}
        #|\ No newline at end of file
        #|+}
        #|```
      ),
    )
    inspect(
      @fs.read_file(@path.join(mock.cwd.path(), "main.mbt")),
      content=(
        #|///|
        #|fn main {
        #|  println("Hello, MoonBit!")
        #|}
        #|
      ),
    )
  })
}

///|
async test "no-op-if-non-moonbit" (t : @test.T) {
  @mock.run(t, timeout=300_000, mock => {
    let model = @model.open_router_model(api_key="")
    // no agent needed since no syntax fixing is required
    let moon_mod_file = mock.add_file("moon.mod.json") // empty file
    let agent = @agent.new(model, logger=mock.logger, cwd=mock.cwd.path())
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @meta_write_to_file.new(agent).to_agent_tool(),
    ])
    let result = @tool.call(@meta_write_to_file.new(agent), {
      "path": "moon.mod.json",
      "replace": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "description": "Update the moon.mod.json file to ensure it has the correct name and version.",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(
      output.message,
      content="File written successfully to moon.mod.json",
    )
    inspect(
      moon_mod_file.read().trim_space(),
      content=(
        #|{ "name": "example", "version": "0.1.0" }
      ),
    )
  })
}

///|
async test "no-op-if-no-syntax-error" (t : @test.T) {
  @mock.run(t, mock => {
    let model = @model.open_router_model(api_key="")
    mock.add_files([
      (
        "moon.mod.json",
        (
          #| { "name": "example", "version": "0.1.0" }
        ),
      ),
      (
        "moon.pkg.json",
        (
          #|{ "is-main": true }
        ),
      ),
    ])
    let main_mbt_file = mock.add_file("main.mbt")
    let agent = @agent.new(model, logger=mock.logger, cwd=mock.cwd.path())
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @meta_write_to_file.new(agent).to_agent_tool(),
    ])
    let result = @tool.call(@meta_write_to_file.new(agent), {
      "path": "main.mbt",
      "replace": (
        #|///|
        #|enum Color {
        #|  Red
        #|  Green
        #|  Blue
        #|}
        #|
        #|///|
        #|fn Color::to_string(color : Color) -> String {
        #|  match color {
        #|    Red => "red"
        #|    Green => "green"
        #|    Blue => "blue"
        #|  }
        #|}
        #|
        #|///|
        #|fn main {
        #|  println(Color::to_string(Blue))
        #|}
      ),
      "description": "Add an enum Color with variants Red, Green, and Blue, a function to_string that converts a Color to its string representation, and a main function that prints the string representation of Color::Blue.",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(
      output.message,
      content="File written and formatted successfully to main.mbt",
    )
    inspect(
      main_mbt_file.read().trim_space(),
      content=(
        #|///|
        #|enum Color {
        #|  Red
        #|  Green
        #|  Blue
        #|}
        #|
        #|///|
        #|fn Color::to_string(color : Color) -> String {
        #|  match color {
        #|    Red => "red"
        #|    Green => "green"
        #|    Blue => "blue"
        #|  }
        #|}
        #|
        #|///|
        #|fn main {
        #|  println(Color::to_string(Blue))
        #|}
      ),
    )
  })
}

///|
async test "fuzzy-search" (t : @test.T) {
  @mock.run(t, mock => {
    let model = @model.open_router_model(api_key="")
    // no syntax error triggered
    mock.add_files([
      (
        "moon.mod.json",
        (
          #|{ "name": "example", "version": "0.1.0" }
        ),
      ),
      (
        "moon.pkg.json",
        (
          #|{ "is-main": true }
        ),
      ),
    ])
    let main_mbt_file = mock.add_file(
      "main.mbt",
      content=(
        #|fn main {
        #|  println("Hello, world!")
        #|
        #|  println("This is a test.")
        #|}
      ),
    )
    let agent = @agent.new(model, logger=mock.logger, cwd=mock.cwd.path())
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @meta_write_to_file.new(agent).to_agent_tool(),
    ])
    let result = @tool.call(@meta_write_to_file.new(agent), {
      "path": "main.mbt",
      "search": (
        #|fn main {
        #|  println("Hello, world!")    
        #|  
        #|  println("This is a test.")    
        #|}
      ),
      "replace": (
        #|///|
        #|fn main {
        #|  println("Hello, world!")
        #|}
        #|
      ),
      "description": "Remove the second println statement from the main function in main.mbt.",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    inspect(
      output.message,
      content="Changes applied and formatted successfully to main.mbt",
    )
    let main_mbt_text = main_mbt_file.read().trim_space()
    inspect(
      main_mbt_text,
      content=(
        #|///|
        #|fn main {
        #|  println("Hello, world!")
        #|}
      ),
    )
  })
}
