///|
async test "replace-segment" (t : @test.Test) {
  @mock.run(t, mock => {
    mock.add_files({
      "moon.mod.json": (
        #|{ "name": "example", "version": "0.1.0" }
      ),
      "moon.pkg.json": (
        #|{ }
      ),
    })
    let example_mbt = mock.add_file(
      "example.mbt",
      content=(
        #|///|
        #|let x : Int = 42
        #|
        #|///|
        #|let y : String = "hello"
      ),
    )
    let moon = @moon.Module::load(mock.cwd.path())
    let files = moon.files().collect()
    json_inspect(files, content=[
      {
        "content": "///|\nlet x : Int = 42\n\n///|\nlet y : String = \"hello\"",
        "header": { "start": 0, "end": 0, "diagnostics": ["Diagnostics", []] },
        "segments": [
          { "start": 0, "end": 3, "diagnostics": ["Diagnostics", []] },
          { "start": 3, "end": 5, "diagnostics": ["Diagnostics", []] },
        ],
        "diagnostics": ["Diagnostics", []],
      },
    ])
    let file = files[0]
    let segments = file.segments()
    json_inspect(mock.json(segments), content=[
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 1,
        "content": "///|\nlet x : Int = 42\n",
      },
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 2,
        "content": "///|\nlet y : String = \"hello\"",
      },
    ])
    file.write(
      file
      .segment(0)
      .replace(
        (
          #|///|
          #|let x : Int = 100
          #|
        ),
      ),
    )
    json_inspect(mock.json(file.segments()), content=[
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 1,
        "content": "///|\nlet x : Int = 100\n",
      },
      {
        "file": "(mock:cwd)/example.mbt",
        "index": 2,
        "content": "///|\nlet y : String = \"hello\"",
      },
    ])
    inspect(
      @fsx.read_file(example_mbt.path()),
      content=(
        #|///|
        #|let x : Int = 100
        #|
        #|///|
        #|let y : String = "hello"
      ),
    )
    file.write(
      file
      .segment(1)
      .replace(
        (
          #|///|
          #|let y : String = "world"
          #|
        ),
      ),
    )
    inspect(
      @fsx.read_file(example_mbt.path()),
      content=(
        #|///|
        #|let x : Int = 100
        #|
        #|///|
        #|let y : String = "world"
        #|
      ),
    )
  })
}

///|
async test "replace_segment/list" (t : @test.Test) {
  @mock.run(t, mock => {
    mock
    .add_file("moon.mod.json")
    .write_string(
      Json::object({
        "name": "username/example",
        "version": "0.1.0",
        "entry": "main.moon",
        "dependencies": {},
      }).stringify(indent=2),
    )
    let list_pkg = mock.add_directory("list")
    list_pkg
    .add_file("moon.pkg.json")
    .write_string(Json::object({}).stringify(indent=2))
    list_pkg
    .add_file("types.mbt")
    .write_string(
      (
        #|#alias(T, deprecated)
        #|pub enum List[A] {
        #|  Empty
        #|  More(A, mut tail~ : List[A])
        #|} derive(Eq)
      ),
    )
    list_pkg
    .add_file("list.mbt")
    .write_string(
      (
        #|///|
        #|/// Get the length of the list.
        #|#alias(length, deprecated)
        #|pub fn[A] List::len(self : List[A]) -> Int {
        #|  loop (self, 0) {
        #|    (Empty, len) => len
        #|    (More(_, tail=rest), acc) => continue (rest, acc + 1)
        #|  }
        #|}
        #|
        #|///|
        #|/// ToJson implementation for List.
        #|/// Converts a list to a JSON array.
        #|pub impl[A : ToJson] ToJson for List[A] with to_json(self) {
        #|  let capacity = self.length()
        #|  guard capacity != 0 else { return [] }
        #|  let jsons = Array::new(capacity~)
        #|  for a in self {
        #|    jsons.push(a.to_json())
        #|  }
        #|  Json::array(jsons)
        #|}
        #|
        #|
        #|///|
        #|/// Maps the list.
        #|pub fn[A, B] List::map(self : List[A], f : (A) -> B raise?) -> List[B] raise? {
        #|  match self {
        #|    Empty => Empty
        #|    More(hd, tail~) => {
        #|      let dest = More(f(hd), tail=Empty)
        #|      loop (dest, tail) {
        #|        (_, Empty) => ()
        #|        (More(_) as dest, More(hd, tail~)) => {
        #|          dest.tail = More(f(hd), tail=Empty)
        #|          continue (dest.tail, tail)
        #|        }
        #|        // unreachable
        #|        (Empty, _) => panic()
        #|      }
        #|      dest
        #|    }
        #|  }
        #|}
        #|
        #|
        #|///|
        #|/// Create an iterator over the list elements.
        #|///
        #|/// Returns an iterator that yields each element of the list in order.
        #|pub fn[A] List::iterator(self : List[A]) -> Iterator[A] {
        #|  let mut next = self
        #|  Iterator::new(() => {
        #|    match next {
        #|      Empty => None
        #|      More(head, tail~) => {
        #|        next = tail
        #|        Some(head)
        #|      }
        #|    }
        #|  })
        #|}
        #|
      ),
    )
    let moon = @moon.Module::load(mock.cwd.path())
    moon.check()
    json_inspect(mock.json(moon.diagnostics()), content=[
      "Diagnostics",
      [
        {
          "error_code": 20,
          "level": "Warning",
          "loc": {
            "end": { "col": 29, "line": 15 },
            "path": "(mock:cwd)/list/list.mbt",
            "start": { "col": 23, "line": 15 },
          },
          "message": "Warning (deprecated): `length` is deprecated, use `len` instead",
        },
        {
          "error_code": 20,
          "level": "Warning",
          "loc": {
            "end": { "col": 56, "line": 51 },
            "path": "(mock:cwd)/list/list.mbt",
            "start": { "col": 45, "line": 51 },
          },
          "message": "Warning (deprecated): The name `Iterator` is deprecated, use `Iter` instead. Note that if you have defined `iterator()` method to support `for .. in` loop, you should also rename `iterator()` to `iter()`. See https://github.com/moonbitlang/core/pull/3127 for more details.",
        },
        {
          "error_code": 20,
          "level": "Warning",
          "loc": {
            "end": { "col": 11, "line": 53 },
            "path": "(mock:cwd)/list/list.mbt",
            "start": { "col": 3, "line": 53 },
          },
          "message": "Warning (deprecated): The name `Iterator` is deprecated, use `Iter` instead. Note that if you have defined `iterator()` method to support `for .. in` loop, you should also rename `iterator()` to `iter()`. See https://github.com/moonbitlang/core/pull/3127 for more details.",
        },
      ],
    ])
    let files = moon.files().collect()
    let file = files[0]
    inspect(
      file.segment(0).content(),
      content=(
        #|///|
        #|/// Get the length of the list.
        #|#alias(length, deprecated)
        #|pub fn[A] List::len(self : List[A]) -> Int {
        #|  loop (self, 0) {
        #|    (Empty, len) => len
        #|    (More(_, tail=rest), acc) => continue (rest, acc + 1)
        #|  }
        #|}
        #|
      ),
    )
    inspect(
      file.segment(1).content(),
      content=(
        #|///|
        #|/// ToJson implementation for List.
        #|/// Converts a list to a JSON array.
        #|pub impl[A : ToJson] ToJson for List[A] with to_json(self) {
        #|  let capacity = self.length()
        #|  guard capacity != 0 else { return [] }
        #|  let jsons = Array::new(capacity~)
        #|  for a in self {
        #|    jsons.push(a.to_json())
        #|  }
        #|  Json::array(jsons)
        #|}
        #|
        #|
      ),
    )
    inspect(
      file.segment(2).content(),
      content=(
        #|///|
        #|/// Maps the list.
        #|pub fn[A, B] List::map(self : List[A], f : (A) -> B raise?) -> List[B] raise? {
        #|  match self {
        #|    Empty => Empty
        #|    More(hd, tail~) => {
        #|      let dest = More(f(hd), tail=Empty)
        #|      loop (dest, tail) {
        #|        (_, Empty) => ()
        #|        (More(_) as dest, More(hd, tail~)) => {
        #|          dest.tail = More(f(hd), tail=Empty)
        #|          continue (dest.tail, tail)
        #|        }
        #|        // unreachable
        #|        (Empty, _) => panic()
        #|      }
        #|      dest
        #|    }
        #|  }
        #|}
        #|
        #|
      ),
    )
    file.write(
      file
      .segment(2)
      .replace(
        (
          #|///|
          #|/// ToJson implementation for List.
          #|/// Converts a list to a JSON array.
          #|pub impl[A : ToJson] ToJson for List[A] with to_json(self) {
          #|  let capacity = self.len()
          #|  guard capacity != 0 else { return [] }
          #|  let jsons = Array::new(capacity~)
          #|  for a in self {
          #|    jsons.push(a.to_json())
          #|  }
          #|  Json::array(jsons)
          #|}
        ),
      ),
    )
    inspect(
      file.segment(3).content(),
      content=(
        #|///|
        #|/// Create an iterator over the list elements.
        #|///
        #|/// Returns an iterator that yields each element of the list in order.
        #|pub fn[A] List::iterator(self : List[A]) -> Iterator[A] {
        #|  let mut next = self
        #|  Iterator::new(() => {
        #|    match next {
        #|      Empty => None
        #|      More(head, tail~) => {
        #|        next = tail
        #|        Some(head)
        #|      }
        #|    }
        #|  })
        #|}
        #|
      ),
    )
  })
}
