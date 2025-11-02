///|
async test "fix-syntax-error" (t : @test.T) {
  @mock.run(t, retry=3, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.open_router_model(api_key~)
    mock.add_files([
      (
        "moon.mod.json",
        Json::object({ "name": "example", "version": "0.1.0" }).stringify(
          indent=2,
        ),
      ),
      ("moon.pkg.json", Json::object({ "is-main": true }).stringify(indent=2)),
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
        #|enum Color {
        #|  Red,
        #|  Green,
        #|  Blue,
        #|}
        #|
        #|fn Color::to_string(self : Color) -> String {
        #|  switch self {
        #|    Red => "red",
        #|    Green => "green",
        #|    Blue => "blue",
        #|  }
        #|}
        #|
        #|fn main() {
        #|
        #|  let color : Color = Blue
        #|  println(color.to_string())
        #|}
      ),
      "description": "Add an enum Color with variants Red, Green, and Blue, a method of Color to_string that converts a Color to its string representation, and a main function that prints the string representation of Color::Blue.",
    })
    guard result is Ok(output) else {
      fail("Expected Ok result but got: \{result}")
    }
    @json.inspect(
      output.message,
      content="File written and formatted successfully to main.mbt",
    )
    // TODO: verify the content is correct by running the program?
    let main_mbt_text = main_mbt_file.read().trim_space()
    // The output is formatted, so we expect it will be resonasbly stable
    inspect(
      main_mbt_text,
      content=(
        #|///|
        #|enum Color {
        #|  Red
        #|  Green
        #|  Blue
        #|}
        #|
        #|///|
        #|fn Color::to_string(self : Color) -> String {
        #|  match self {
        #|    Red => "red"
        #|    Green => "green"
        #|    Blue => "blue"
        #|  }
        #|}
        #|
        #|///|
        #|fn main {
        #|  let color : Color = Blue
        #|  println(color.to_string())
        #|}
      ),
    )
  })
}

///|
async test "search-replace" (t : @test.T) {
  @mock.run(t, retry=3, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.open_router_model(api_key~)
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
        #|}
      ),
      "replace": (
        #|enum Color {
        #|  Red,
        #|  Green,
        #|  Blue,
        #|}
        #|
        #|fn Color::to_string(self : Color) -> String {
        #|  switch self {
        #|    Red => "red",
        #|    Green => "green",
        #|    Blue => "blue",
        #|  }
        #|}
        #|
        #|fn main() {
        #|  let color : Color = Blue
        #|  println(color.to_string())
        #|}
      ),
      "description": "Remove existing placeholder content, then add an enum Color with variants Red, Green, and Blue, a method of Color to_string that converts a Color to its string representation, and a main function that prints the string representation of Color::Blue.",
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
        #|enum Color {
        #|  Red
        #|  Green
        #|  Blue
        #|}
        #|
        #|///|
        #|fn Color::to_string(self : Color) -> String {
        #|  match self {
        #|    Red => "red"
        #|    Green => "green"
        #|    Blue => "blue"
        #|  }
        #|}
        #|
        #|///|
        #|fn main {
        #|  let color : Color = Blue
        #|  println(color.to_string())
        #|}
      ),
    )
  })
}
