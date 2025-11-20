///|
async test "check_patch" (t : @test.Test) {
  @mock.run(t, mock => {
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
          #|{ }
        ),
      ),
      (
        "example.mbt",
        (
          #|///|
          #|let x : Int = "string"
        ),
      ),
    ])
    let moon = @moon.Module::load(mock.cwd.path())
    let files = moon.files().collect()
    @json.inspect(files, content=[
      {
        "content": "///|\nlet x : Int = \"string\"",
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
        "content": "///|\nlet x : Int = \"string\"",
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
                {
                  "error_code": 4014,
                  "level": "Error",
                  "loc": {
                    "end": { "col": 23, "line": 2 },
                    "path": "(mock:cwd)/example.mbt",
                    "start": { "col": 15, "line": 2 },
                  },
                  "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
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
            {
              "error_code": 4014,
              "level": "Error",
              "loc": {
                "end": { "col": 23, "line": 2 },
                "path": "(mock:cwd)/example.mbt",
                "start": { "col": 15, "line": 2 },
              },
              "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
            },
          ],
        ],
      },
    ])
    let file = files[0]
    let segments = file.segments()
    @json.inspect(mock.json(segments), content=[
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 1,
        "content": "///|\nlet x : Int = \"string\"",
      },
    ])
    let segment = segments[0]
    @json.inspect(
      mock.json(moon.check_patch_replace(segment, "///|\nlet x : String = 100")),
      content=[
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
          {
            "error_code": 4014,
            "level": "Error",
            "loc": {
              "end": { "col": 21, "line": 2 },
              "path": "(mock:cwd)/example.mbt",
              "start": { "col": 18, "line": 2 },
            },
            "message": "Expr Type Mismatch\n        has type : Int\n        wanted   : String",
          },
        ],
      ],
    )
  })
}
