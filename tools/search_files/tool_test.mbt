///|
using @path {type Path}

///|
async test "search_files" (t : @test.Test) {
  @mock.run(t, mock => {
    let _ = mock.add_file(
      "notes.txt",
      content=(
        #|These are some notes about the project.
        #|We need to implement a feature to search files.
        #|The search should be efficient and accurate.
      ),
    )
    let args : Json = { "path": ".", "regex": "search files", "kind": "regex" }
    let result = @search_files.new(mock.cwd.path()).call(args)
    guard result is Success(output) else {
      fail("Expected Success result but got: \{result}")
    }
    inspect(
      output.to_message().content(),
      content=(
        #|Search completed. Found 1 matches. Note: gitignore rules were not fully respected during the search as "git check-ignore" fails to execute properly.
        #|
        #|notes.txt:2
        #|1: These are some notes about the project.
        #|2: We need to implement a feature to search files.
        #|3: The search should be efficient and accurate.
        #|
      ),
    )
  })
}

///|
/// FIXME: disabled due to bug in moon IDE find-references tool
#cfg(false)
async test "search_files-moon-definition" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "username/example", "version": "0.1.0" }
      .to_json()
      .stringify(indent=2),
      "moon.pkg.json": Json::object({}).stringify(indent=2),
      "main.mbt": (
        #|///|
        #|pub fn greet(name : String) -> String {
        #|  println("Hello, \{name}!")
        #|}
      ),
    })
    let args : Json = {
      "path": ".",
      "regex": "@username/example.greet",
      "kind": "moonbit_definition",
    }
    let result = @search_files.new(mock.cwd.path()).call(args)
    guard result is Success(output) else {
      fail("Expected Success result but got: \{result}")
    }
    json_inspect(mock.json(output), content=[
      "MoonbitToolResult",
      {
        "kind": "MoonbitDefinition",
        "query": "@username/example.greet",
        "path": ".",
        "working_directory": "(mock:cwd)",
        "output": "",
        "message": "Search completed using fuzzy symbolic search for MoonBit definitions.",
      },
    ])
  })
}

///|
/// FIXME: disabled due to bug in moon IDE find-references tool
#cfg(false)
async test "search_files-moon-references" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "username/example", "version": "0.1.0" }
      .to_json()
      .stringify(indent=2),
      "moon.pkg.json": Json::object({}).stringify(indent=2),
      "main.mbt": (
        #|///|
        #|pub fn greet(name : String) -> String {
        #|  println("Hello, \{name}!")
        #|}
        #|
        #|fn main {
        #|  greet("World")
        #|  greet("MoonBit")
        #|}
      ),
    })
    let args : Json = {
      "path": ".",
      "regex": "@username/example.greet",
      "kind": "moonbit_references",
    }
    let result = @search_files.new(mock.cwd.path()).call(args)
    guard result is Success(output) else {
      fail("Expected Success result but got: \{result}")
    }
    json_inspect(mock.json(output), content=[
      "MoonbitToolResult",
      {
        "kind": "MoonbitReferences",
        "query": "@username/example greet",
        "path": ".",
        "working_directory": "(mock:cwd)",
        "output": "Search completed using MoonBit IDE find-references tool.\nQuery: \"@username/example greet\"\nWorking directory: (mock:cwd)\n\n`pub fn greet` in package username/example at (mock:cwd)/main.mbt:1-4:\n        ^^^^^             ^^^^^^^^^^^^^^^^\n1 | ///|\n  | pub fn greet(name : String) -> String {\n  |   println(\"Hello, \\{name}!\")\n  | }\n\nFound 5 references of this symbol:\n(mock:cwd)/main.mbt:2:8-2:13:\n  | ///|\n2 | pub fn greet(name : String) -> String {\n  |        ^^^^^\n  |   println(\"Hello, \\{name}!\")\n  | }\n\n(mock:cwd)/main.mbt:7:3-7:8:\n  | }\n  | \n  | fn main {\n7 |   greet(\"World\")\n  |   ^^^^^\n  |   greet(\"MoonBit\")\n  | }\n\n(mock:cwd)/main.mbt:8:3-8:8:\n  | \n  | fn main {\n  |   greet(\"World\")\n8 |   greet(\"MoonBit\")\n  |   ^^^^^\n  | }\n\n(mock:cwd)/main.mbt:7:3-7:8:\n  | }\n  | \n  | fn main {\n7 |   greet(\"World\")\n  |   ^^^^^\n  |   greet(\"MoonBit\")\n  | }\n\n(mock:cwd)/main.mbt:8:3-8:8:\n  | \n  | fn main {\n  |   greet(\"World\")\n8 |   greet(\"MoonBit\")\n  |   ^^^^^\n  | }\n\n",
        "message": "Search completed using MoonBit IDE find-references tool.",
      },
    ])
  })
}

///|
async test "search_files/gitignore" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.add_json_tree({
      ".gitignore": (
        #|ignored.txt
      ),
      "ignored.txt": (
        #|This file should be ignored by git.
      ),
      "not_ignored.txt": (
        #|This file should not be ignored by git.
      ),
    })
    let args : Json = { "path": ".", "regex": "file", "kind": "regex" }
    let result = @search_files.new(mock.cwd.path()).call(args)
    guard result is Success(output) else {
      fail("Expected Success result but got: \{result}")
    }
    let result = output.to_message().content()
    inspect(
      result,
      content=(
        #|Search completed. Found 1 matches. Note: gitignore rules were not fully respected during the search as "git check-ignore" fails to execute properly.
        #|
        #|not_ignored.txt:1
        #|1: This file should not be ignored by git.
        #|
      ),
    )
  })
}

///|
async test "search_files/gitignore-without-git" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      ".gitignore": (
        #|ignored.txt
      ),
      "ignored.txt": (
        #|This file should be ignored by git.
      ),
      "not_ignored.txt": (
        #|This file should not be ignored by git.
      ),
    })
    let args : Json = { "path": ".", "regex": "file", "kind": "regex" }
    let tool = @search_files.new(mock.cwd.path())
    let result = tool.call(args)
    guard result is Success(output) else {
      fail("Expected Success result but got: \{result}")
    }
    let result = output.to_message().content()
    inspect(
      result,
      content=(
        #|Search completed. Found 2 matches. Note: gitignore rules were not fully respected during the search as "git check-ignore" fails to execute properly.
        #|
        #|ignored.txt:1
        #|1: This file should be ignored by git.
        #|
        #|not_ignored.txt:1
        #|1: This file should not be ignored by git.
        #|
      ),
    )
  })
}

///|
async test "search_files/does-not-respect-gitignore" (t : @test.Test) {
  @mock.run(t, mock => {
    @git.init_(mock.cwd.path())
    mock.add_json_tree({
      ".gitignore": (
        #|ignored.txt
      ),
      "ignored.txt": (
        #|This file should be ignored by git.
      ),
      "not_ignored.txt": (
        #|This file should not be ignored by git.
      ),
    })
    let args : Json = {
      "path": ".",
      "regex": "ignored",
      "kind": "regex",
      "respect_gitignore": false,
    }
    let result = @search_files.new(mock.cwd.path()).call(args)
    guard result is Success(output) else {
      fail("Expected Success result but got: \{result}")
    }
    let result = output.to_message().content()
    inspect(
      result,
      content=(
        #|Search completed. Found 3 matches.
        #|
        #|.gitignore:1
        #|1: ignored.txt
        #|
        #|ignored.txt:1
        #|1: This file should be ignored by git.
        #|
        #|not_ignored.txt:1
        #|1: This file should not be ignored by git.
        #|
      ),
    )
  })
}
