///|
async test "get_moonbit_coverage" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("get_moonbit_coverage")
    g.add_defer(() => cwd.close())
    let _ = cwd.add_file(
      "moon.mod.json",
      { "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = cwd.add_file("moon.pkg.json", Json::object({}).stringify())
    let _ = cwd.add_file(
      "example.mbt",
      (
        #|///|
        #|pub fn fib(n : Int) -> Int {
        #|  if n <= 1 {
        #|    n
        #|  } else {
        #|    fib(n - 1) + fib(n - 2)
        #|  }
        #|}
      ),
    )
    let _ = cwd.add_file(
      "example_test.mbt",
      (
        #|///|
        #|test "fib" {
        #|  @json.inspect(@example.fib(1), content=1)
        #|}
      ),
    )
    let params = @get_moonbit_coverage.params(
      project_path=cwd.path(),
      file="example.mbt",
    )
    let result = @get_moonbit_coverage.get_moonbit_coverage.call(
      params.to_json(),
      cwd.path(),
    )
    let result : @get_moonbit_coverage.Result = @json.from_json(result.output)
    inspect(
      result,
      content=(
        $|Total: 1 uncovered line(s) in 1 file(s)
        $|
        $|1 uncovered line(s) in example.mbt:
        $|
        $|  | pub fn fib(n : Int) -> Int {
        $|  |   if n <= 1 {
        $|  |     n
        $|  |   } else {
        $|6 |     fib(n - 1) + fib(n - 2)
        $|  |     ^^^^^^^^^^^^^^^^^^^^^^^ \t<-- UNCOVERED
        $|  |   }
        $|  | }
        $|  …
        $|
        $|Total: 1 uncovered line(s) in 1 file(s)
        $|
      ),
    )
  })
}
