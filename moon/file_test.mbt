///|
async test "replace-segment" (t : @test.T) {
  @taco.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = taco.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let example_mbt = taco.add_file(
      "example.mbt",
      content="///|\nlet x : Int = 42",
    )
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
    let file = files[0]
    let segments = file.segments()
    @json.inspect(taco.json(segments), content=[
      {
        "file": "./example.mbt",
        "index": 1,
        "content": "///|\nlet x : Int = 42",
      },
    ])
    file.replace_segment(0, "///|\nlet y : Int = 100")
    let files = moon.files().collect()
    @json.inspect(files, content=[
      {
        "content": "///|\nlet y : Int = 100\n",
        "header": { "start": 0, "end": 0, "diagnostics": [] },
        "segments": [{ "start": 0, "end": 3, "diagnostics": [] }],
        "diagnostics": [],
      },
    ])
    @json.inspect(
      @fs.read_file(example_mbt.path()),
      content="///|\nlet y : Int = 100\n",
    )
  })
}
