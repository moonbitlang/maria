///|
test "int64" {
  inspect(
    @jsonx.int64(1234567890123456789).stringify(),
    content="1234567890123456789",
  )
}

///|
test "int64/zero" {
  inspect(@jsonx.int64(0).stringify(), content="0")
}

///|
test "int64/negative" {
  inspect(
    @jsonx.int64(-1234567890123456789).stringify(),
    content="-1234567890123456789",
  )
}

///|
test "int64/small" {
  inspect(@jsonx.int64(42).stringify(), content="42")
}

///|
test "int64/min" {
  inspect(
    @jsonx.int64(@int64.min_value).stringify(),
    content="-9223372036854775808",
  )
}

///|
test "int64/max" {
  inspect(
    @jsonx.int64(@int64.max_value).stringify(),
    content="9223372036854775807",
  )
}

///|
priv struct Int64Data {
  value : Int64
} derive(ToJson)

///|
impl @json.FromJson for Int64Data with from_json(json, path) {
  let object = @jsonx.as_object(json, path~)
  let value = object.required_int64("value", path~)
  { value, }
}

///|
test "as_int64/with-repr" {
  let json : Json = { "value": Json::number(0.0, repr="1234567890123456789") }
  let data : Int64Data = @json.from_json(json)
  inspect(data.value, content="1234567890123456789")
}

///|
test "as_int64/without-repr" {
  let json : Json = { "value": 42.0 }
  let data : Int64Data = @json.from_json(json)
  inspect(data.value, content="42")
}

///|
test "as_int64/string-type" {
  let json : Json = { "value": "not a number" }
  let result : Result[Int64Data, @json.JsonDecodeError] = try? @json.from_json(
    json,
  )
  json_inspect(result, content={
    "Err": ["JsonDecodeError", ["/value", "Int64::as_int64: expected number"]],
  })
}

///|
test "as_int64/invalid-repr" {
  let json : Json = { "value": Json::number(0.0, repr="not_a_number") }
  let result : Result[Int64Data, @json.JsonDecodeError] = try? @json.from_json(
    json,
  )
  match result {
    Err(_) => ()
    Ok(_) => fail("expected error for invalid repr")
  }
}

///|
test "required_int64/present" {
  let json : Json = { "value": Json::number(0.0, repr="9876543210") }
  let data : Int64Data = @json.from_json(json)
  inspect(data.value, content="9876543210")
}

///|
test "required_int64/missing" {
  let json : Json = { "other": 123.0 }
  let result : Result[Int64Data, @json.JsonDecodeError] = try? @json.from_json(
    json,
  )
  json_inspect(result, content={
    "Err": ["JsonDecodeError", ["/value", "field 'value' is required"]],
  })
}

///|
test "int64/round-trip" {
  let original : Int64 = 1234567890123456789
  let json = @jsonx.int64(original)
  let data : Int64Data = @json.from_json({ "value": json })
  inspect(data.value, content="1234567890123456789")
  assert_eq(data.value, original)
}

///|
test "int64/round-trip-max" {
  let original : Int64 = @int64.max_value
  let json = @jsonx.int64(original)
  let data : Int64Data = @json.from_json({ "value": json })
  inspect(data.value, content="9223372036854775807")
  assert_eq(data.value, original)
}

///|
priv struct OptionalInt64Data {
  value : Int64?
}

///|
impl @json.FromJson for OptionalInt64Data with from_json(json, path) {
  let object = @jsonx.as_object(json, path~)
  let value = object.optional_int64("value", path~)
  { value, }
}

///|
test "optional_int64/present" {
  let json : Json = { "value": Json::number(0.0, repr="1234567890") }
  let data : OptionalInt64Data = @json.from_json(json)
  inspect(data.value, content="Some(1234567890)")
}

///|
test "optional_int64/missing" {
  let json : Json = { "other": 123.0 }
  let data : OptionalInt64Data = @json.from_json(json)
  inspect(data.value, content="None")
}

///|
test "optional_int64/null" {
  let json : Json = { "value": null }
  let data : OptionalInt64Data = @json.from_json(json)
  inspect(data.value, content="None")
}
