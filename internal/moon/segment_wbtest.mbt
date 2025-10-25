///|
async test "segment" (t : @test.T) {
  @mock.run(t, mock => {
    let file = mock.add_file(
      "example.mbt",
      content=(
        #|// Header
        #|///| a
        #|let x : Int = 5
        #|///| b
        #|let y : String = \"hello\"
        #|///|
        #|/// c
        #|fn greet() -> String {
        #|  y
        #|}
        #|///|
      ),
    )
    let file = File::new(file.path())
    file.load()
    @json.inspect(mock.json(file.segments()), content=[
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 1,
        "content": "///| a\nlet x : Int = 5",
      },
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 2,
        "content": "///| b\nlet y : String = \\\"hello\\\"",
      },
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 3,
        "content": "///|\n/// c\nfn greet() -> String {\n  y\n}",
      },
      { "file": "(mock:cwd)/example.mbt", "index": 4, "content": "///|" },
    ])
  })
}
