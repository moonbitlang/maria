///|
async test "files" (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([
      (
        "moon.mod.json",
        (
          #|{ "name": "example", "version": "0.1.0" }
        ),
      ),
      (
        "moon.pkg.json",
        (
          #|{ }
        ),
      ),
      ("example.mbt", "///|\nlet x : Int = 42"),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    let files = moon.files().collect()
    @json.inspect(files, content=[
      {
        "content": "///|\nlet x : Int = 42",
        "header": { "start": 0, "end": 0, "diagnostics": [] },
        "segments": [{ "start": 0, "end": 2, "diagnostics": [] }],
        "diagnostics": [],
      },
    ])
    moon.check()
    let files = moon.files().collect()
    @json.inspect(taco.json(files), content=[
      {
        "content": "///|\nlet x : Int = 42",
        "header": { "start": 0, "end": 0, "diagnostics": [] },
        "segments": [
          {
            "start": 0,
            "end": 2,
            "diagnostics": [
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
          },
        ],
        "diagnostics": [
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
      },
    ])
    let segments = []
    for file in files {
      segments.push(file.segments())
    }
    @json.inspect(taco.json(segments), content=[
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
async test "interface" (t : @test.T) {
  @mock.run(t, taco => {
    taco.add_files([
      (
        "moon.mod.json",
        (
          #|{ "name": "example", "version": "0.1.0" }
        ),
      ),
      (
        "moon.pkg.json",
        (
          #|{ }
        ),
      ),
      ("example.mbt", "let x : Int = 42"),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    let pkg = moon.package_("example")
    @json.inspect(taco.json(pkg), content=[
      {
        "name": "example",
        "path": "(mock:cwd)",
        "files": {
          "(mock:cwd)/example.mbt": {
            "content": "let x : Int = 42",
            "header": { "start": 0, "end": 1, "diagnostics": [] },
            "segments": [],
            "diagnostics": [],
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
async test "diagnostics" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = taco.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = taco.add_file("example.mbt", content="let x : Int = \"string\"")
    let moon = Module::load(taco.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics().collect()
    @json.inspect(taco.json(diagnostics), content=[
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
    ])
  })
}

///|
async test "packages" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0", "source": "src" }
        .to_json()
        .stringify(),
    )
    let src = taco.add_directory("src")
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
    let util = taco.add_directory("util")
    let _ = util.add_file("helpers.mbt", content="let x : Int = 42")
    let src_app = src.add_directory("app")
    let _ = src_app.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let _ = src_app.add_file("main.mbt", content="let y : String = \"hello\"")
    let moon = @moon.Module::load(taco.cwd.path())
    let pkg_names = moon.packages().map(pkg => pkg.name()).collect()
    pkg_names.sort()
    @json.inspect(pkg_names, content=[
      "example", "example/app", "example/lib", "example/lib/util",
    ])
  })
}
