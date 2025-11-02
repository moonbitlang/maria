///|
test "Loc::from_json" {
  let loc_json : Array[Json] = [
    {
      "end": { "col": 10, "line": 5 },
      "path": "example.mbt",
      "start": { "col": 5, "line": 5 },
    },
    {
      "end": { "col": 23, "line": 5 },
      "path": "src/main.mbt",
      "start": { "col": 15, "line": 5 },
    },
    {
      "end": { "col": 2, "line": 10 },
      "path": "test.mbt",
      "start": { "col": 1, "line": 5 },
    },
  ]
  fn round_trip(x : Json) -> Json raise {
    let loc : Loc = @json.from_json(x)
    loc.to_json()
  }

  @json.inspect(loc_json.map(round_trip), content=[
    {
      "end": { "col": 10, "line": 5 },
      "path": "example.mbt",
      "start": { "col": 5, "line": 5 },
    },
    {
      "end": { "col": 23, "line": 5 },
      "path": "src/main.mbt",
      "start": { "col": 15, "line": 5 },
    },
    {
      "end": { "col": 2, "line": 10 },
      "path": "test.mbt",
      "start": { "col": 1, "line": 5 },
    },
  ])
}

///|
test "Loc::from_json - error cases" {
  let test_cases : Array[(String, Json)] = [
    (
      "missing start",
      { "end": { "col": 10, "line": 5 }, "path": "example.mbt" },
    ),
    ("missing end", { "path": "example.mbt", "start": { "col": 5, "line": 5 } }),
    (
      "missing path",
      { "end": { "col": 10, "line": 5 }, "start": { "col": 5, "line": 5 } },
    ),
    (
      "invalid Pos in start",
      {
        "end": { "col": 10, "line": 5 },
        "path": "example.mbt",
        "start": { "line": 5 },
      },
    ),
  ]
  let results = test_cases.map(fn(case) {
    let (_, json) = case
    try {
      let _loc : Loc = @json.from_json(json)
      "success"
    } catch {
      @json.JsonDecodeError(_) => "error"
    }
  })
  inspect(results.join(","), content="error,error,error,error")
}

///|
test "Pos::from_json" {
  let pos_json : Array[Json] = [
    { "col": 15, "line": 42 },
    { "col": 5, "line": 10, "extra": "ignored" },
  ]
  fn round_trip(x : Json) -> Json raise {
    let pos : Pos = @json.from_json(x)
    pos.to_json()
  }

  @json.inspect(pos_json.map(round_trip), content=[
    { "col": 15, "line": 42 },
    { "col": 5, "line": 10 },
  ])
}

///|
test "Pos::from_json - error cases" {
  let test_cases : Array[(String, Json)] = [
    ("missing col", { "line": 10 }),
    ("missing line", { "col": 5 }),
    ("invalid type for col", { "col": "not a number", "line": 10 }),
  ]
  let results = test_cases.map(fn(case) {
    let (_, json) = case
    try {
      let _pos : Pos = @json.from_json(json)
      "success"
    } catch {
      @json.JsonDecodeError(_) => "error"
    }
  })
  inspect(results.join(","), content="error,error,error")
}

///|
test "Level::from_json" {
  let level_json : Array[Json] = ["error", "warning"]
  fn round_trip(x : Json) -> Json raise {
    let level : Level = @json.from_json(x)
    level.to_json()
  }

  @json.inspect(level_json.map(round_trip), content=["Error", "Warning"])
}

///|
test "Level::from_json - error cases" {
  let test_cases : Array[Json] = ["info", "debug", "critical"]
  let results = test_cases.map(fn(json) {
    try {
      let _level : Level = @json.from_json(json)
      "success"
    } catch {
      @json.JsonDecodeError(_) => "error"
    }
  })
  inspect(results.join(","), content="error,error,error")
}

///|
test "Diagnostic::from_json" {
  let diag_json : Array[Json] = [
    {
      "error_code": 4014,
      "level": "error",
      "loc": {
        "end": { "col": 23, "line": 1 },
        "path": "example.mbt",
        "start": { "col": 15, "line": 1 },
      },
      "message": "Expr Type Mismatch",
    },
    {
      "error_code": 2,
      "level": "warning",
      "loc": {
        "end": { "col": 6, "line": 1 },
        "path": "test.mbt",
        "start": { "col": 5, "line": 1 },
      },
      "message": "Warning: Unused variable 'x'",
    },
    {
      "error_code": 100,
      "level": "warning",
      "loc": {
        "end": { "col": 5, "line": 3 },
        "path": "lib.mbt",
        "start": { "col": 1, "line": 3 },
      },
      "message": "Test warning",
      "extra_field": "should be ignored",
      "another": 42,
    },
    // Real world output from  `moon check --output-json`
    {
      "$message_type": "diagnostic",
      "level": "warning",
      "loc": {
        "path": "/Users/git/maria/internal/moon/module.mbt",
        "start": { "line": 218, "col": 21 },
        "end": { "line": 218, "col": 26 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
      "error_code": 2000,
    },
    {
      "$message_type": "diagnostic",
      "level": "warning",
      "loc": {
        "path": "/Users/git/maria/internal/moon/package.mbt",
        "start": { "line": 151, "col": 3 },
        "end": { "line": 151, "col": 8 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
      "error_code": 2000,
    },
    {
      "$message_type": "diagnostic",
      "level": "warning",
      "loc": {
        "path": "/Users/git/maria/internal/moon/check_wbtest.mbt",
        "start": { "line": 19, "col": 23 },
        "end": { "line": 19, "col": 28 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
      "error_code": 2000,
    },
    {
      "$message_type": "diagnostic",
      "level": "warning",
      "loc": {
        "path": "/Users/git/maria/internal/moon/module.mbt",
        "start": { "line": 218, "col": 21 },
        "end": { "line": 218, "col": 26 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
      "error_code": 2000,
    },
    {
      "$message_type": "diagnostic",
      "level": "warning",
      "loc": {
        "path": "/Users/git/maria/internal/moon/package.mbt",
        "start": { "line": 151, "col": 3 },
        "end": { "line": 151, "col": 8 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
      "error_code": 2000,
    },
  ]
  fn round_trip(x : Json) -> Json raise {
    let diag : Diagnostic = @json.from_json(x)
    diag.to_json()
  }

  // Note: Level serialization produces "Error"/"Warning" not "error"/"warning"
  @json.inspect(diag_json.map(round_trip), content=[
    {
      "error_code": 4014,
      "level": "Error",
      "loc": {
        "end": { "col": 23, "line": 1 },
        "path": "example.mbt",
        "start": { "col": 15, "line": 1 },
      },
      "message": "Expr Type Mismatch",
    },
    {
      "error_code": 2,
      "level": "Warning",
      "loc": {
        "end": { "col": 6, "line": 1 },
        "path": "test.mbt",
        "start": { "col": 5, "line": 1 },
      },
      "message": "Warning: Unused variable 'x'",
    },
    {
      "error_code": 100,
      "level": "Warning",
      "loc": {
        "end": { "col": 5, "line": 3 },
        "path": "lib.mbt",
        "start": { "col": 1, "line": 3 },
      },
      "message": "Test warning",
    },
    {
      "error_code": 2000,
      "level": "Warning",
      "loc": {
        "end": { "col": 26, "line": 218 },
        "path": "/Users/git/maria/internal/moon/module.mbt",
        "start": { "col": 21, "line": 218 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
    },
    {
      "error_code": 2000,
      "level": "Warning",
      "loc": {
        "end": { "col": 8, "line": 151 },
        "path": "/Users/git/maria/internal/moon/package.mbt",
        "start": { "col": 3, "line": 151 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
    },
    {
      "error_code": 2000,
      "level": "Warning",
      "loc": {
        "end": { "col": 28, "line": 19 },
        "path": "/Users/git/maria/internal/moon/check_wbtest.mbt",
        "start": { "col": 23, "line": 19 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
    },
    {
      "error_code": 2000,
      "level": "Warning",
      "loc": {
        "end": { "col": 26, "line": 218 },
        "path": "/Users/git/maria/internal/moon/module.mbt",
        "start": { "col": 21, "line": 218 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
    },
    {
      "error_code": 2000,
      "level": "Warning",
      "loc": {
        "end": { "col": 8, "line": 151 },
        "path": "/Users/git/maria/internal/moon/package.mbt",
        "start": { "col": 3, "line": 151 },
      },
      "message": "Warning (Alert deprecated): This function is deprecated.",
    },
  ])
}

///|
test "Diagnostic::from_json - error cases" {
  let test_cases : Array[(String, Json)] = [
    (
      "missing error_code",
      {
        "level": "error",
        "loc": {
          "end": { "col": 10, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Some error",
      },
    ),
    (
      "missing level",
      {
        "error_code": 123,
        "loc": {
          "end": { "col": 10, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
        "message": "Some error",
      },
    ),
    (
      "missing loc",
      { "error_code": 123, "level": "error", "message": "Some error" },
    ),
    (
      "missing message",
      {
        "error_code": 123,
        "level": "error",
        "loc": {
          "end": { "col": 10, "line": 1 },
          "path": "test.mbt",
          "start": { "col": 5, "line": 1 },
        },
      },
    ),
  ]
  let results = test_cases.map(fn(case) {
    let (_, json) = case
    try {
      let _diag : Diagnostic = @json.from_json(json)
      "success"
    } catch {
      @json.JsonDecodeError(_) => "error"
    }
  })
  inspect(results.join(","), content="error,error,error,error")
}
