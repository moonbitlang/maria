///|
async test "Coverage::report" (t : @test.T) {
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
          #|  if n == 0 {
          #|    1
          #|  } else if n == 1 {
          #|    1
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
          #|  @json.inspect(@example.fib(0), content=1)
          #|}
        ),
      ),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    moon.check()
    @json.inspect(moon.diagnostics(), content=["Diagnostics", []])
    @json.inspect(moon.test_(enable_coverage=true), content=[])
    @json.inspect(
      moon.coverage.report(format=Summary),
      content=(
        #|example.mbt: 2/6
        #|Total: 2/6
        #|
      ),
    )
    // TODO: wait for https://github.com/moonbitlang/maria/pull/248
    let cwd_path = @path.Path::parse(taco.cwd.path() + "/")
    let path_builder = @path.PathBuilder::from_path(cwd_path)
    path_builder.set_file(base="coverage", extension="json")
    let coverage_path = path_builder.to_string()
    @json.inspect(
      moon.coverage.report(format=Coveralls, output_file=coverage_path),
    )
    @json.inspect(@json.parse(@fs.read_file(coverage_path)), content={
      "source_files": [
        {
          "name": "example.mbt",
          "source_digest": "fd5f82b005628fbe3ba4a2a8e641f974",
          "coverage": [null, null, 1, 1, 0, 0, null, 0, null, null],
        },
      ],
    })
  })
}

///|
async test "Coverage::analyze" (t : @test.T) {
  @mock.run(t, timeout=300_000, taco => {
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
          #|  if n == 0 {
          #|    1
          #|  } else if n == 1 {
          #|    1
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
          #|  @json.inspect(@example.fib(0), content=1)
          #|}
        ),
      ),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    moon.check()
    @json.inspect(moon.diagnostics(), content=["Diagnostics", []])
    @json.inspect(moon.test_(enable_coverage=true), content=[])
    @json.inspect(
      moon.coverage.analyze(),
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

///|
async test "Coverage::clean" (t : @test.T) {
  @mock.run(t, timeout=300_000, taco => {
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
          #|  if n == 0 {
          #|    1
          #|  } else if n == 1 {
          #|    1
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
          #|  @json.inspect(@example.fib(0), content=1)
          #|}
        ),
      ),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    moon.check()
    @json.inspect(moon.diagnostics(), content=["Diagnostics", []])
    @json.inspect(moon.test_(enable_coverage=true), content=[])
    @json.inspect(
      moon.coverage.report(format=Summary),
      content="example.mbt: 2/6\nTotal: 2/6\n",
    )
    @json.inspect(moon.coverage.clean())
    @json.inspect(
      (try? moon.coverage.report(format=Summary)) is Err(_),
      content=true,
    )
  })
}
