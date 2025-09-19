///|
async test "files" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-module")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file("example.mbt", "///|\nlet x : Int = 42")
    let moon = Module::load(cwd.path())
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
    @json.inspect(cwd.strip_cwd(files), content=[
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
                  "path": "./example.mbt",
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
              "path": "./example.mbt",
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
    @json.inspect(cwd.strip_cwd(segments), content=([[{"file":"./example.mbt","index":1,"content":"///|\nlet x : Int = 42"}]]))
  })
}
