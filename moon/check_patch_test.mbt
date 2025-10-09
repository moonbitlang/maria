///|
async test "check_patch" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-check-patch")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("example.mbt", "///|\nlet x : Int = \"string\"")
    let moon = Module::load(cwd.path())
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
    @json.inspect(cwd.strip_cwd(files), content=[
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
                  "path": "./example.mbt",
                  "start": { "col": 5, "line": 2 },
                },
                "message": "Warning: Unused variable 'x'",
              },
              {
                "error_code": 4014,
                "level": "Error",
                "loc": {
                  "end": { "col": 23, "line": 2 },
                  "path": "./example.mbt",
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
              "path": "./example.mbt",
              "start": { "col": 5, "line": 2 },
            },
            "message": "Warning: Unused variable 'x'",
          },
          {
            "error_code": 4014,
            "level": "Error",
            "loc": {
              "end": { "col": 23, "line": 2 },
              "path": "./example.mbt",
              "start": { "col": 15, "line": 2 },
            },
            "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
          },
        ],
      },
    ])
    let file = files[0]
    let segments = file.segments()
    @json.inspect(cwd.strip_cwd(segments), content=[
      {
        "file": "./example.mbt",
        "index": 1,
        "content": "///|\nlet x : Int = \"string\"",
      },
    ])
    let segment = segments[0]
    @json.inspect(
      cwd.strip_cwd(
        moon.check_patch_replace(segment, "///|\nlet x : String = 100"),
      ),
      content=[
        {
          "error_code": 4014,
          "level": "Error",
          "loc": {
            "end": { "col": 21, "line": 2 },
            "path": "./example.mbt",
            "start": { "col": 18, "line": 2 },
          },
          "message": "Expr Type Mismatch\n        has type : Int\n        wanted   : String",
        },
      ],
    )
  })
}
