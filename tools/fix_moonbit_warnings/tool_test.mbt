///|
#skip
async test "fix_moonbit_warnings" (t : @test.Test) {
  @mock.run(t, mock => {
    let model = mock.model(name=ClaudeHaiku4_5)
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
    list_pkg.add_files({
      "moon.pkg.json": Json::object({}).stringify(indent=2),
      "types.mbt": (
        #|#alias(T, deprecated)
        #|pub enum MutList[A] {
        #|  Empty
        #|  More(A, mut tail~ : MutList[A])
        #|} derive(Eq)
      ),
      "list.mbt": (
        #|///|
        #|/// Get the length of the list.
        #|#alias(length, deprecated)
        #|pub fn[A] MutList::len(self : MutList[A]) -> Int {
        #|  loop (self, 0) {
        #|    (Empty, len) => len
        #|    (More(_, tail=rest), acc) => continue (rest, acc + 1)
        #|  }
        #|}
        #|
        #|///|
        #|/// ToJson implementation for MutList.
        #|/// Converts a list to a JSON array.
        #|pub impl[A : ToJson] ToJson for MutList[A] with to_json(self) {
        #|  let capacity = self.length()
        #|  guard capacity != 0 else { return [] }
        #|  let jsons = Array::new(capacity~)
        #|  for a in self {
        #|    jsons.push(a.to_json())
        #|  }
        #|  Json::array(jsons)
        #|}
        #|
        #|///|
        #|/// FromJson implementation for MutList.
        #|/// Parses a JSON array into a list.
        #|pub impl[A : @json.FromJson] @json.FromJson for MutList[A] with from_json(
        #|  json,
        #|  path,
        #|) {
        #|  guard json is Array(arr) else {
        #|    raise @json.JsonDecodeError((path, "@list.from_json: expected array"))
        #|  }
        #|  for i = arr.length() - 1, list = Empty; i >= 0; {
        #|    continue i - 1, list.add(A::from_json(arr[i], path.add_index(i)))
        #|  } else {
        #|    list
        #|  }
        #|}
        #|
        #|///|
        #|/// Prepend an element to the front of the list.
        #|///
        #|/// Creates a new list with the given element added to the beginning.
        #|#alias(add, deprecated)
        #|pub fn[A] MutList::prepend(self : MutList[A], head : A) -> MutList[A] {
        #|  More(head, tail=self)
        #|}
        #|
        #|///|
        #|/// Maps the list.
        #|pub fn[A, B] MutList::map(self : MutList[A], f : (A) -> B raise?) -> MutList[B] raise? {
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
        #|///|
        #|/// Create an iterator over the list elements.
        #|///
        #|/// Returns an iterator that yields each element of the list in order.
        #|pub fn[A] MutList::iterator(self : MutList[A]) -> Iterator[A] {
        #|  let mut next = self
        #|  Iterator::new(fn() {
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
    })
    let agent = @agent.new(model, cwd=mock.cwd.path(), logger=mock.logger)
    let tool = @fix_moonbit_warnings.new(agent)
    let args : Json = {
      "project_path": mock.cwd.path(),
      "description": "Fix all MoonBit warnings/errors in the project.",
    }
    let output = tool.call(args)
    guard output is Ok(result) else {
      fail("Expected tool call to succeed, got error: \{output}")
      return
    }
    inspect(result, content="Processed 2 files and updated 3 segments.")
  })
}
