///|
async test "check_patch" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = taco.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = taco.add_file(
      "example.mbt",
      content="///|\nlet x : Int = \"string\"",
    )
    let moon = Module::load(taco.cwd.path())
    let files = moon.files().collect()
    @json.inspect(files, content=[
      {
        "content": "///|\nlet x : Int = \"string\"",
        "header": { "start": 0, "end": 0, "diagnostics": [] },
        "segments": [{ "start": 0, "end": 2, "diagnostics": [] }],
        "diagnostics": [],
      },
    ])
    moon.check()
    let files = moon.files().collect()
    @json.inspect(taco.json(files), content=[
      {
        "content": "///|\nlet x : Int = \"string\"",
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
      },
    ])
    let file = files[0]
    let segments = file.segments()
    @json.inspect(taco.json(segments), content=[
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 1,
        "content": "///|\nlet x : Int = \"string\"",
      },
    ])
    let segment = segments[0]
    @json.inspect(
      taco.json(moon.check_patch_replace(segment, "///|\nlet x : String = 100")),
      content=[
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
    )
  })
}
