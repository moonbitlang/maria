///|
async test "files" (t : @test.T) {
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
      ("example.mbt", "///|\nlet x : Int = 42"),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    let files = moon.files().collect()
    @json.inspect(files, content=[
      {
        "content": "///|\nlet x : Int = 42",
        "header": { "start": 0, "end": 0, "diagnostics": [] },
        "segments": [{ "start": 0, "end": 2, "diagnostics": [] }],
        "diagnostics": [],
      },
    ])
    moon.check()
    let files = moon.files().collect()
    @json.inspect(taco.json(files), content=[
      {
        "content": "///|\nlet x : Int = 42",
        "header": { "start": 0, "end": 0, "diagnostics": [] },
        "segments": [
          {
            "start": 0,
            "end": 2,
            "diagnostics": [
              {
                "error_code": 2,
                "level": "Warning",
                "loc": {
                  "end": { "col": 6, "line": 2 },
                  "path": "(mock:cwd)/example.mbt",
                  "start": { "col": 5, "line": 2 },
                },
                "message": "Warning: Unused variable 'x'",
              },
            ],
          },
        ],
        "diagnostics": [
          {
            "error_code": 2,
            "level": "Warning",
            "loc": {
              "end": { "col": 6, "line": 2 },
              "path": "(mock:cwd)/example.mbt",
              "start": { "col": 5, "line": 2 },
            },
            "message": "Warning: Unused variable 'x'",
          },
        ],
      },
    ])
    let segments = []
    for file in files {
      segments.push(file.segments())
    }
    @json.inspect(taco.json(segments), content=[
      [
        {
          "file": "(mock:cwd)/example.mbt",
          "index": 1,
          "content": "///|\nlet x : Int = 42",
        },
      ],
    ])
  })
}

///|
async test "interface" (t : @test.T) {
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
      ("example.mbt", "let x : Int = 42"),
    ])
    let moon = @moon.Module::load(taco.cwd.path())
    let pkg = moon.find_package("example")
    @json.inspect(taco.json(pkg), content=[
      {
        "name": "example",
        "path": "(mock:cwd)",
        "files": {
          "(mock:cwd)/example.mbt": {
            "content": "let x : Int = 42",
            "header": { "start": 0, "end": 1, "diagnostics": [] },
            "segments": [],
            "diagnostics": [],
          },
        },
      },
    ])
    guard pkg is Some(pkg)
    let interface = pkg.interface()
    inspect(
      interface,
      content=(
        #|// Generated using `moon info`, DON'T EDIT IT
        #|package "example"
        #|
        #|// Values
        #|
        #|// Errors
        #|
        #|// Types and methods
        #|
        #|// Type aliases
        #|
        #|// Traits
        #|
        #|
      ),
    )
  })
}

///|
async test "diagnostics" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = taco.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = taco.add_file("example.mbt", content="let x : Int = \"string\"")
    let moon = Module::load(taco.cwd.path())
    moon.check()
    let diagnostics = moon.diagnostics().collect()
    @json.inspect(taco.json(diagnostics), content=[
      {
        "error_code": 2,
        "level": "Warning",
        "loc": {
          "end": { "col": 6, "line": 1 },
          "path": "(mock:cwd)/example.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Warning: Unused variable 'x'",
      },
      {
        "error_code": 4014,
        "level": "Error",
        "loc": {
          "end": { "col": 23, "line": 1 },
          "path": "(mock:cwd)/example.mbt",
          "start": { "col": 15, "line": 1 },
        },
        "message": "Expr Type Mismatch\n        has type : String\n        wanted   : Int",
      },
    ])
  })
}

///|
async test "interface/core" (t : @test.T) {
  @mock.run(t, mock => {
    let _ = mock.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0" }.to_json().stringify(),
    )
    let _ = mock.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let _ = mock.add_file("example.mbt", content="let x : Int = \"string\"")
    let moon = Module::load(mock.cwd.path())
    let pkg = moon
      .find_package("moonbitlang/core/set")
      .or_error(Failure("Package not found"))
    inspect(pkg.interface(), content=(
      #|// Generated using `moon info`, DON'T EDIT IT
      #|package "moonbitlang/core/set"
      #|
      #|// Values
      #|
      #|// Errors
      #|
      #|// Types and methods
      #|type Set[K]
      #|fn[K : Hash + Eq] Set::add(Self[K], K) -> Unit
      #|fn[K : Hash + Eq] Set::add_and_check(Self[K], K) -> Bool
      #|fn[K] Set::capacity(Self[K]) -> Int
      #|fn[K] Set::clear(Self[K]) -> Unit
      #|fn[K : Hash + Eq] Set::contains(Self[K], K) -> Bool
      #|fn[K] Set::copy(Self[K]) -> Self[K]
      #|fn[K] Set::default() -> Self[K] // from trait `Default`
      #|fn[K : Hash + Eq] Set::difference(Self[K], Self[K]) -> Self[K]
      #|fn[K] Set::each(Self[K], (K) -> Unit raise?) -> Unit raise?
      #|fn[K] Set::eachi(Self[K], (Int, K) -> Unit raise?) -> Unit raise?
      #|fn[K : Hash + Eq] Set::equal(Self[K], Self[K]) -> Bool // from trait `Eq`
      #|#as_free_fn
      #|fn[K : Hash + Eq] Set::from_array(Array[K]) -> Self[K]
      #|#as_free_fn
      #|fn[K : Hash + Eq] Set::from_iter(Iter[K]) -> Self[K]
      #|#deprecated
      #|fn[K : Hash + Eq] Set::insert(Self[K], K) -> Unit
      #|fn[K : Hash + Eq] Set::intersection(Self[K], Self[K]) -> Self[K]
      #|fn[K : Hash + Eq] Set::is_disjoint(Self[K], Self[K]) -> Bool
      #|fn[K] Set::is_empty(Self[K]) -> Bool
      #|fn[K : Hash + Eq] Set::is_subset(Self[K], Self[K]) -> Bool
      #|fn[K : Hash + Eq] Set::is_superset(Self[K], Self[K]) -> Bool
      #|fn[K] Set::iter(Self[K]) -> Iter[K]
      #|fn[K : Hash + Eq] Set::land(Self[K], Self[K]) -> Self[K] // from trait `BitAnd`
      #|#alias(size, deprecated)
      #|fn[K] Set::length(Self[K]) -> Int
      #|fn[K : Hash + Eq] Set::lor(Self[K], Self[K]) -> Self[K] // from trait `BitOr`
      #|fn[K : Hash + Eq] Set::lxor(Self[K], Self[K]) -> Self[K] // from trait `BitXOr`
      #|#as_free_fn
      #|fn[K] Set::new(capacity? : Int) -> Self[K]
      #|#as_free_fn
      #|fn[K : Hash + Eq] Set::of(FixedArray[K]) -> Self[K]
      #|#deprecated
      #|fn[K : Hash + Eq] Set::op_equal(Self[K], Self[K]) -> Bool // from trait `Eq`
      #|#deprecated
      #|fn[K : Hash + Eq] Set::op_sub(Self[K], Self[K]) -> Self[K] // from trait `Sub`
      #|fn[K : Show] Set::output(Self[K], &Logger) -> Unit // from trait `Show`
      #|fn[K : Hash + Eq] Set::remove(Self[K], K) -> Unit
      #|fn[K : Hash + Eq] Set::remove_and_check(Self[K], K) -> Bool
      #|fn[K : Hash + Eq] Set::sub(Self[K], Self[K]) -> Self[K] // from trait `Sub`
      #|fn[K : Hash + Eq] Set::symmetric_difference(Self[K], Self[K]) -> Self[K]
      #|fn[K] Set::to_array(Self[K]) -> Array[K]
      #|fn[X : ToJson] Set::to_json(Self[X]) -> Json // from trait `ToJson`
      #|fn[K : Show] Set::to_string(Self[K]) -> String // from trait `Show`
      #|fn[K : Hash + Eq] Set::union(Self[K], Self[K]) -> Self[K]
      #|impl[K : Hash + Eq] BitAnd for Set[K]
      #|impl[K : Hash + Eq] BitOr for Set[K]
      #|impl[K : Hash + Eq] BitXOr for Set[K]
      #|impl[K] Default for Set[K]
      #|impl[K : Hash + Eq] Eq for Set[K]
      #|impl[K : Show] Show for Set[K]
      #|impl[K : Hash + Eq] Sub for Set[K]
      #|impl[X : ToJson] ToJson for Set[X]
      #|
      #|// Type aliases
      #|
      #|// Traits
      #|
      #|
    ))
  })
}

///|
async test "packages" (t : @test.T) {
  @mock.run(t, taco => {
    let _ = taco.add_file(
      "moon.mod.json",
      content={ "name": "example", "version": "0.1.0", "source": "src" }
        .to_json()
        .stringify(),
    )
    let src = taco.add_directory("src")
    let _ = src.add_file("moon.pkg.json", content=Json::object({}).stringify())
    let src_lib = src.add_directory("lib")
    let _ = src_lib.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let src_lib_util = src_lib.add_directory("util")
    let _ = src_lib_util.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let util = taco.add_directory("util")
    let _ = util.add_file("helpers.mbt", content="let x : Int = 42")
    let src_app = src.add_directory("app")
    let _ = src_app.add_file(
      "moon.pkg.json",
      content=Json::object({}).stringify(),
    )
    let _ = src_app.add_file("main.mbt", content="let y : String = \"hello\"")
    let moon = @moon.Module::load(taco.cwd.path())
    let pkg_names = moon.packages().map(pkg => pkg.name()).collect()
    pkg_names.sort()
    @json.inspect(pkg_names, content=[
      "example", "example/app", "example/lib", "example/lib/util",
    ])
  })
}
