///|
async test "files" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
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
    @json.inspect(files, content=[
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
    @json.inspect(mock.json(files), content=[
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
                  "message": "Warning: Unused variable 'x'",
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
              "message": "Warning: Unused variable 'x'",
            },
          ],
        ],
      },
    ])
    let segments = []
    for file in files {
      segments.push(file.segments())
    }
    @json.inspect(mock.json(segments), content=[
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
    mock.add_files({
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
    @json.inspect(mock.json(pkg), content=[
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
    let _ = mock.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = mock.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = mock.add_file("example.mbt", content="let x : Int = \"string\"")
    let moon = Module::load(mock.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics()
    @json.inspect(mock.json(diagnostics), content=[
      "Diagnostics",
      [
        {
          "error_code": 2,
          "level": "Warning",
          "loc": {
            "end": { "col": 6, "line": 1 },
            "path": "(mock:cwd)/example.mbt",
            "start": { "col": 5, "line": 1 },
          },
          "message": "Warning: Unused variable 'x'",
        },
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
      ],
    ])
  })
}

///|
async test "interface/core" (t : @test.Test) {
  @mock.run(t, mock => {
    let _ = mock.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = mock.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = mock.add_file("example.mbt", content="let x : Int = \"string\"")
    let moon = Module::load(mock.cwd.path())
    let pkg = moon
      .find_package("moonbitlang/core/set")
      .unwrap_or_error(Failure("Package not found"))
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
        #|fn[K : Hash + Eq] Set::add(Self[K], K) -> Unit
        #|fn[K : Hash + Eq] Set::add_and_check(Self[K], K) -> Bool
      ),
    )
  })
}

///|
async test "packages" (t : @test.Test) {
  @mock.run(t, mock => {
    let _ = mock.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0", "source": "src" }
        .to_json()
        .stringify(),
    )
    let src = mock.add_directory("src")
    let _ = src.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let src_lib = src.add_directory("lib")
    let _ = src_lib.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let src_lib_util = src_lib.add_directory("util")
    let _ = src_lib_util.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let util = mock.add_directory("util")
    let _ = util.add_file("helpers.mbt", content="let x : Int = 42")
    let src_app = src.add_directory("app")
    let _ = src_app.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let _ = src_app.add_file("main.mbt", content="let y : String = \"hello\"")
    let moon = @moon.Module::load(mock.cwd.path())
    let pkg_names = moon.packages().map(pkg => pkg.name()).collect()
    pkg_names.sort()
    @json.inspect(pkg_names, content=[
      "example", "example/app", "example/lib", "example/lib/util",
    ])
  })
}
