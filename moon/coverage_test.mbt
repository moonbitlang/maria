///|
async test "coverage_analyze" {
  @async.with_task_group(g => {
    let cwd = @mock.directory("moon-coverage")
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
        #|  if n == 0 {
        #|    1
        #|  } else if n == 1 {
        #|    1
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
        #|  @json.inspect(@example.fib(0), content=1)
        #|}
      ),
    )
    let moon = @moon.Module::load(cwd.path())
    moon.check()
    @json.inspect(moon.diagnostics().collect(), content=[])
    @json.inspect(moon.test_(), content=[])
    @json.inspect(
      moon.coverage_analyze(),
      content=(
        #|Total: 2 uncovered line(s) in 1 file(s)
        #|
        #|2 uncovered line(s) in example.mbt:
        #|
        #|   | pub fn fib(n : Int) -> Int {
        #|   |   if n == 0 {
        #|   |     1
        #| 5 |   } else if n == 1 {
        $|   |   ^^^^^^^^^^^^^^^^^^ \t<-- UNCOVERED
        #|   |     1
        #|   |   } else {
        #| 8 |     fib(n - 1) + fib(n - 2)
        $|   |     ^^^^^^^^^^^^^^^^^^^^^^^ \t<-- UNCOVERED
        #|   |   }
        #|   | }
        #|   …
        #|
        #|Total: 2 uncovered line(s) in 1 file(s)
        #|
      ),
    )
  })
}
