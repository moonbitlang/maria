///|
async test "check_moonbit_project" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-check-moonbit-project")
    g.add_defer(() => cwd.close())
    @fs.write_to_file(
      @path.join(cwd.path(), "moon.mod.json"),
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    @fs.write_to_file(
      @path.join(cwd.path(), "moon.pkg.json"),
      Json::object({}).stringify(),
    )
    @fs.write_to_file(
      @path.join(cwd.path(), "example.mbt"),
      "///|\nlet x : Int = \"string\"",
    )
    let args = @check_moonbit_project.params(
      diagnostic_limit=10,
      project_path=cwd.path(),
    )
    let result = @check_moonbit_project.check_moonbit_project.call(
      args.to_json(),
      cwd.path(),
    )
    @json.inspect(cwd.strip_cwd(result), content={
      "output": {
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
        "diagnostic_limit": 10,
      },
    })
  })
}

///|
async test "check_moonbit_project/patch-insert" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-check-moonbit-project-patch")
    g.add_defer(() => cwd.close())
    @fs.write_to_file(
      @path.join(cwd.path(), "moon.mod.json"),
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    @fs.write_to_file(
      @path.join(cwd.path(), "moon.pkg.json"),
      Json::object({}).stringify(),
    )
    @fs.write_to_file(
      @path.join(cwd.path(), "example.mbt"),
      "///|\nlet x : Int = \"string\"\n",
    )
    let args = @check_moonbit_project.params(
      diagnostic_limit=10,
      project_path=cwd.path(),
      patch_code="let y : String = 42",
      patch_file_name="example.mbt",
    )
    let result = @check_moonbit_project.check_moonbit_project.call(
      args.to_json(),
      cwd.path(),
    )
    @json.inspect(cwd.strip_cwd(result), content={
      "output": {
        "diagnostics": [
          {
            "error_code": 2,
            "level": "Warning",
            "loc": {
              "end": { "col": 6, "line": 1 },
              "path": "./example.mbt",
              "start": { "col": 5, "line": 1 },
            },
            "message": "Warning: Unused variable 'y'",
          },
          {
            "error_code": 4014,
            "level": "Error",
            "loc": {
              "end": { "col": 20, "line": 1 },
              "path": "./example.mbt",
              "start": { "col": 18, "line": 1 },
            },
            "message": "Expr Type Mismatch\n        has type : Int\n        wanted   : String",
          },
        ],
        "diagnostic_limit": 10,
      },
    })
  })
}
