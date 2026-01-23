///|
async test "files" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": "///|\nlet x : Int = 42",
    })
    let moon = @moon.Module::load(mock.cwd.path())
    let files = moon.files().collect()
    json_inspect(files, content=[
      {
        "content": "///|\nlet x : Int = 42",
        "header": { "start": 0, "end": 0, "diagnostics": ["Diagnostics", []] },
        "segments": [
          { "start": 0, "end": 2, "diagnostics": ["Diagnostics", []] },
        ],
        "diagnostics": ["Diagnostics", []],
      },
    ])
    moon.check()
    let files = moon.files().collect()
    json_inspect(mock.json(files), content=[
      {
        "content": "///|\nlet x : Int = 42",
        "header": { "start": 0, "end": 0, "diagnostics": ["Diagnostics", []] },
        "segments": [
          {
            "start": 0,
            "end": 2,
            "diagnostics": [
              "Diagnostics",
              [
                {
                  "error_code": 2,
                  "level": "Warning",
                  "loc": {
                    "end": { "col": 6, "line": 2 },
                    "path": "(mock:cwd)/example.mbt",
                    "start": { "col": 5, "line": 2 },
                  },
                  "message": "Warning (unused_value): Unused variable 'x'",
                },
              ],
            ],
          },
        ],
        "diagnostics": [
          "Diagnostics",
          [
            {
              "error_code": 2,
              "level": "Warning",
              "loc": {
                "end": { "col": 6, "line": 2 },
                "path": "(mock:cwd)/example.mbt",
                "start": { "col": 5, "line": 2 },
              },
              "message": "Warning (unused_value): Unused variable 'x'",
            },
          ],
        ],
      },
    ])
    let segments = []
    for file in files {
      segments.push(file.segments())
    }
    json_inspect(mock.json(segments), content=[
      [
        {
          "file": "(mock:cwd)/example.mbt",
          "index": 1,
          "content": "///|\nlet x : Int = 42",
        },
      ],
    ])
  })
}

///|
async test "interface" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
      "example.mbt": "let x : Int = 42",
    })
    let moon = @moon.Module::load(mock.cwd.path())
    let pkg = moon.find_package("example")
    json_inspect(mock.json(pkg), content=[
      {
        "name": "example",
        "path": "(mock:cwd)",
        "files": {
          "(mock:cwd)/example.mbt": {
            "content": "let x : Int = 42",
            "header": {
              "start": 0,
              "end": 1,
              "diagnostics": ["Diagnostics", []],
            },
            "segments": [],
            "diagnostics": ["Diagnostics", []],
          },
        },
      },
    ])
    guard pkg is Some(pkg)
    let interface = pkg.interface()
    inspect(
      interface,
      content=(
        #|// Generated using `moon info`, DON'T EDIT IT
        #|package "example"
        #|
        #|// Values
        #|
        #|// Errors
        #|
        #|// Types and methods
        #|
        #|// Type aliases
        #|
        #|// Traits
        #|
        #|
      ),
    )
  })
}

///|
async test "diagnostics" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "example", "version": "0.1.0" }
      .to_json()
      .stringify(),
      "moon.pkg.json": Json::object({}).stringify(),
      "example.mbt": "let x : Int = \"string\"",
    })
    let moon = Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    json_inspect(mock.json(diagnostics), content=[
      "Diagnostics",
      [
        {
          "error_code": 4014,
          "level": "Error",
          "loc": {
            "end": { "col": 23, "line": 1 },
            "path": "(mock:cwd)/example.mbt",
            "start": { "col": 15, "line": 1 },
          },
          "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
        },
        {
          "error_code": 2,
          "level": "Warning",
          "loc": {
            "end": { "col": 6, "line": 1 },
            "path": "(mock:cwd)/example.mbt",
            "start": { "col": 5, "line": 1 },
          },
          "message": "Warning (unused_value): Unused variable 'x'",
        },
      ],
    ])
  })
}

///|
async test "interface/core" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": { "name": "example", "version": "0.1.0" }
      .to_json()
      .stringify(),
      "moon.pkg.json": Json::object({}).stringify(),
      "example.mbt": "let x : Int = \"string\"",
    })
    let moon = Module::load(mock.cwd.path())
    let pkg = moon
      .find_package("moonbitlang/core/set")
      .unwrap_or_error(Failure::Failure("Package not found"))
    inspect(
      pkg.interface().split("\n")[0:12].to_array().join("\n"),
      content=(
        #|// Generated using `moon info`, DON'T EDIT IT
        #|package "moonbitlang/core/set"
        #|
        #|// Values
        #|
        #|// Errors
        #|
        #|// Types and methods
        #|type Set[K]
        #|#alias(insert, deprecated)
        #|pub fn[K : Hash + Eq] Set::add(Self[K], K) -> Unit
        #|pub fn[K : Hash + Eq] Set::add_and_check(Self[K], K) -> Bool
      ),
    )
  })
}

///|
async test "packages" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_json_tree({
      "moon.mod.json": {
        "name": "example",
        "version": "0.1.0",
        "source": "src",
      }
      .to_json()
      .stringify(),
      "src": {
        "moon.pkg.json": Json::object({}).stringify(),
        "lib": {
          "moon.pkg.json": Json::object({}).stringify(),
          "util": { "moon.pkg.json": Json::object({}).stringify() },
        },
        "app": {
          "moon.pkg.json": Json::object({}).stringify(),
          "main.mbt": "let y : String = \"hello\"",
        },
      },
      "util": { "helpers.mbt": "let x : Int = 42" },
    })
    let moon = @moon.Module::load(mock.cwd.path())
    let pkg_names = moon.packages().map(pkg => pkg.name()).collect()
    pkg_names.sort()
    json_inspect(pkg_names, content=[
      "example", "example/app", "example/lib", "example/lib/util",
    ])
  })
}
