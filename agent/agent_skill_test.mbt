///|
async test "skill" (t : @test.Test) {
  @mock.run(t, retry=3, mock => {
    mock.add_json_tree({
      "moon.mod.json": Json::object({ "name": "example", "version": "0.1.0" }).stringify(
        indent=2,
      ),
      "moon.pkg.json": Json::object({}).stringify(indent=2),
      "example.mbt": (
        #|///|
        #|pub fn fib(n : Int) -> Int64 {
        #|  loop (n, 0L, 1L) {
        #|    (0, _, b) => b
        #|    (i, a, b) => continue (i - 1, b, a + b)
        #|  }
        #|}
        #|
        #|///|
        #|/// data is a labelled argument without default value having type Array[Int]
        #|/// start is an optional labelled argument with default value 0 having type Int
        #|/// length is an optional labelled argument without default value having type Option[Int]
        #|/// ```mbt check
        #|/// test {
        #|///   inspect(1, content="1")
        #|/// }
        #|/// ```
        #|pub fn sum(data~ : Array[Int], start? : Int = 0, length? : Int) -> Int {
        #|  let end = if length is Some(length) { start + length } else { data.length() }
        #|  for i = start, sum = 0; i < end; i = i + 1, sum = sum + data[i] {
        #|
        #|  } else {
        #|    sum
        #|  }
        #|}
      ),
      ".moonagent": {
        "skills": {
          "moonbit-query-documentation": {
            "SKILL.md": (
              #|---
              #|name: moonbit-query-documentation
              #|description: A skill to look up code documentation using `moon doc`
              #|license: MIT
              #|---
              #|
              #|You can use `moon doc <query>` to discover available APIs and
              #|their documentation in the current project and its dependencies.
              #|
              #|### Query Syntax
              #|
              #|`moon doc` uses a specialized query syntax designed for symbol lookup:
              #|
              #|- **Empty query**: `moon doc `
              #|
              #|  - In a module: shows all available packages in current module
              #|  - In a package: shows all symbols in current package
              #|  - Outside package: shows all available packages
              #|
              #|- **Function/value lookup**: `moon doc "[@pkg.]sym"`
              #|
              #|- **Type lookup**: `moon doc "[@pkg.]Sym"`
              #|
              #|- **Method/field lookup**: `moon doc "[@pkg.]T::sym"`
              #|
              #|- **Package exploration**: `moon doc "@pkg"`
              #|  - Show package `pkg` and list all its exported symbols
              #|  - Example: `moon doc "@json"` - explore entire `@json` package
              #|  - Example: `moon doc "@encoding/utf8"` - explore nested package
              #|
              #|### Examples
              #|
              #|````bash
              #|# search for String methods in standard library:
              #|$ moon doc "String"
              #|
              #|type String
              #|
              #|  pub fn String::add(String, String) -> String
              #|  pub fn String::at(String, Int) -> Int
              #|  # ... more methods omitted ...
              #|
              #|# list all symbols in a standard library package:
              #|$ moon doc "@buffer"
              #|moonbitlang/core/buffer
              #|
              #|fn from_array(ArrayView[Byte]) -> Buffer
              #|fn from_bytes(Bytes) -> Buffer
              #|# ... more functions omitted ...
              #|
              #|# list the specific function in a package:
              #|$ moon doc "@buffer.new"
              #|package "moonbitlang/core/buffer"
              #|
              #|pub fn new(size_hint? : Int) -> Buffer
              #|  Creates a new extensible buffer with specified initial capacity. If the
              #|   initial capacity is less than 1, the buffer will be initialized with capacity
              #|   1.
              #|# ... more details omitted ...
              #|
              #|$ moon doc "String::*rev*"
              #|package "moonbitlang/core/string"
              #|
              #|pub fn String::rev(String) -> String
              #|  Returns a new string with the characters in reverse order. It respects
              #|   Unicode characters and surrogate pairs but not grapheme clusters.
              #|
              #|pub fn String::rev_find(String, StringView) -> Int?
              #|  Returns the offset (charcode index) of the last occurrence of the given
              #|   substring. If the substring is not found, it returns None.
              #|````
            ),
          },
        },
      },
    })
    let model = mock.model(name=ClaudeSonnet4_5)
    let agent = @agent.new(
      model,
      cwd=mock.cwd.path(),
      user_message="Show me the documentation of `Array::length` function in example.mbt.",
    )
    let job_manager = @job.Manager::new(cwd=agent.cwd)
    let file_manager = @file.manager(cwd=agent.cwd)
    let todo_list = @todo.new(uuid=agent.uuid, cwd=agent.cwd)
    agent.add_tools([
      @execute_command.new(job_manager).to_agent_tool(),
      @list_files.new(file_manager).to_agent_tool(),
      @read_file.new(file_manager).to_agent_tool(),
      @todo.new_tool(todo_list).to_agent_tool(),
    ])
    let tool_calls = []
    agent.add_listener(event => {
      match event.desc {
        PostToolCall(tool_call, ..) => tool_calls.push(tool_call)
        _ => ()
      }
    })
    agent.start()
    fn contains_read_file_skill_md(
      tool_calls : Array[@ai.ToolCall],
    ) -> Bool raise {
      for tool_call in tool_calls {
        if tool_call.name == "read_file" {
          guard tool_call.arguments is Some(arguments) else { continue }
          let args = @json.parse(arguments)
          guard args is Json::Object(obj) else { continue }
          guard obj.get("path") is Some(Json::String(path)) else { continue }
          if path.has_suffix("SKILL.md") || path.has_suffix("skill.md") {
            return true
          }
        }
      }
      return false
    }

    fn contains_moon_doc(tool_calls : Array[@ai.ToolCall]) -> Bool raise {
      for tool_call in tool_calls {
        if tool_call.name == "execute_command" {
          guard tool_call.arguments is Some(arguments) else { continue }
          let args = @json.parse(arguments)
          guard args is Json::Object(obj) else { continue }
          guard obj.get("command") is Some(Json::String(command)) else {
            continue
          }
          if command.contains("moon doc") {
            return true
          }
        }
      }
      return false
    }

    assert_true(contains_read_file_skill_md(tool_calls))
    assert_true(contains_moon_doc(tool_calls))
  })
}
