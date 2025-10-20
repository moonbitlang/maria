///|
async test "get_moonbit_coverage" (t : @test.T) {
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
      (
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
      ),
      (
        "example_test.mbt",
        (
          #|///|
          #|test "fib" {
          #|  @json.inspect(@example.fib(1), content=1)
          #|}
        ),
      ),
    ])
    let params = params(project_path=taco.cwd.path(), file="example.mbt")
    let result = get_moonbit_coverage.call(params.to_json(), taco.cwd.path())
    let result : Result = @json.from_json(result.output())
    @json.inspect(
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
        $|  |     ^^^^^^^^^^^^^^^^^^^^^^^ 	<-- UNCOVERED
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
