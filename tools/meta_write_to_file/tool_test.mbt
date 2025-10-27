///|
async test "meta_write_to_file/no-op-if-no-syntax-error" (t : @test.T) {
  @mock.run(t, timeout=300_000, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="qwen/qwen3-coder-plus",
      safe_zone_tokens=200000,
    )
    let _ = mock.add_file(
      "moon.mod.json",
      content=Json::object({ "name": "example", "version": "0.1.0" }).stringify(
        indent=2,
      ),
    )
    let _ = mock.add_file(
      "moon.pkg.json",
      content=Json::object({ "is-main": true }).stringify(indent=2),
    )
    let main_mbt_file = mock.add_file("main.mbt")
    let agent = @agent.new(model, cwd=mock.cwd.path())
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @meta_write_to_file.new(agent).to_agent_tool(),
    ])
    let result = @tool.Tool::call(@meta_write_to_file.new(agent), {
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
      content="File written successfully to main.mbt",
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
async test "meta_write_to_file/fix-syntax-error" (t : @test.T) {
  @mock.run(t, timeout=300_000, retry=3, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="qwen/qwen3-coder-plus",
      safe_zone_tokens=200000,
    )
    let _ = mock.add_file(
      "moon.mod.json",
      content=Json::object({ "name": "example", "version": "0.1.0" }).stringify(
        indent=2,
      ),
    )
    let _ = mock.add_file(
      "moon.pkg.json",
      content=Json::object({ "is-main": true }).stringify(indent=2),
    )
    let main_mbt_file = mock.add_file("main.mbt")
    let agent = @agent.new(model, cwd=mock.cwd.path())
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @meta_write_to_file.new(agent).to_agent_tool(),
    ])
    let result = @tool.Tool::call(@meta_write_to_file.new(agent), {
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
      content="File written successfully to main.mbt",
    )
    let main_mbt_text = main_mbt_file.read().trim_space()
    @regexp.compile(regexp_string, flags="m").execute(main_mbt_text).matched()
    |> @json.inspect(content=true)
  })
}

///|
let regexp_string : String =
  #|\/\/\/\|\s*
  #|enum Color \{\s*
  #|  Red\s*
  #|  Green\s*
  #|  Blue\s*
  #|\}\s*
  #|\s*
  #|\/\/\/\|\s*
  #|fn Color::to_string\(self : Color\) -> String \{\s*
  #|  match self \{\s*
  #|    (Color::)?Red => "red"\s*
  #|    (Color::)?Green => "green"\s*
  #|    (Color::)?Blue => "blue"\s*
  #|  \}\s*
  #|\}\s*
  #|\s*
  #|\/\/\/\|\s*
  #|fn main \{\s*
  #|  let color : Color = (Color::)?Blue\s*
  #|  println\(color\.to_string\(\)\)\s*
  #|\}\s*

///|
test "regexp" {
  let regexp = @regexp.compile(regexp_string, flags="m")
  regexp
  .execute(
    (
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
    ),
  )
  .matched()
  |> @json.inspect(content=false)
  regexp
  .execute(
    (
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
  .matched()
  |> @json.inspect(content=true)
  regexp
  .execute(
    (
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
      #|    Color::Red => "red"
      #|    Color::Green => "green"
      #|    Color::Blue => "blue"
      #|  }
      #|}
      #|
      #|///|
      #|fn main {
      #|  let color : Color = Color::Blue
      #|  println(color.to_string())
      #|}
    ),
  )
  .matched()
  |> @json.inspect(content=true)
}

///|
async test "meta_write_to_file/search-replace" (t : @test.T) {
  @mock.run(t, timeout=300_000, retry=3, mock => {
    let api_key = mock.getenv("OPENAI_API_KEY")
    let model = @model.new(
      api_key~,
      base_url="https://openrouter.ai/api/v1",
      name="qwen/qwen3-coder-plus",
      safe_zone_tokens=200000,
    )
    let _ = mock.add_file(
      "moon.mod.json",
      content=Json::object({ "name": "example", "version": "0.1.0" }).stringify(
        indent=2,
      ),
    )
    let _ = mock.add_file(
      "moon.pkg.json",
      content=Json::object({ "is-main": true }).stringify(indent=2),
    )
    let main_mbt_file = mock.add_file(
      "main.mbt",
      content=(
        #|fn main {
        #|  println("Hello, world!")
        #|}
      ),
    )
    let agent = @agent.new(model, cwd=mock.cwd.path())
    let file_manager = @file.manager(cwd=mock.cwd.path())
    agent.add_tools([
      @replace_in_file.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @meta_write_to_file.new(agent).to_agent_tool(),
    ])
    let result = @tool.Tool::call(@meta_write_to_file.new(agent), {
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
    @json.inspect(output.message, content="Changes applied to main.mbt")
    let main_mbt_text = main_mbt_file.read().trim_space()
    @regexp.compile(regexp_string, flags="m").execute(main_mbt_text).matched()
    |> @json.inspect(content=true)
  })
}
