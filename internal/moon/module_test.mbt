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
    let moon = Module::load(taco.cwd.path())
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
    let moon = Module::load(taco.cwd.path())
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
