///|
async test "replace-segment" (t : @test.T) {
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
    ])
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
        "file": "(mock:cwd)/example.mbt",
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
