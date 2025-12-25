///|
priv struct People {
  name : String
  age : Int
  active : Bool
  /// Optional field for testing purposes
  nickname : String?
} derive(ToJson)

///|
impl @json.FromJson for People with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "People::from_json: expected object"))
  }
  let name : String = @jsonx.get_required(obj, "name", path~)
  let age : Int = @jsonx.get_required(obj, "age", path~)
  let active : Bool = @jsonx.get_required(obj, "active", path~)
  let nickname : String? = @jsonx.get_nullable(obj, "nickname", path~)
  People::{ name, age, active, nickname }
}

///|
test "@jsonx.get_required" {
  let object : Json = {
    "name": "Alice",
    "age": 25.0,
    "active": true,
    "nickname": "Ally",
  }
  let people : People = @json.from_json(object)
  @json.inspect(people, content={
    "name": "Alice",
    "age": 25,
    "active": true,
    "nickname": "Ally",
  })
}

///|
test "@jsonx.get_required/missing-field" {
  let object : Json = { "name": "Bob" }
  let people : Result[People, @json.JsonDecodeError] = try? @json.from_json(
    object,
  )
  @json.inspect(people, content={
    "Err": ["JsonDecodeError", ["/age", "field 'age' is required"]],
  })
}

///|
test "@json.get_nullable/not-present" {
  let object : Json = { "name": "Alice", "age": 25.0, "active": true }
  let people : People = @json.from_json(object)
  @json.inspect(people, content={ "name": "Alice", "age": 25, "active": true })
}

///|
test "@json.get_nullable/explicit-null" {
  let object : Json = {
    "name": "Alice",
    "age": 25.0,
    "active": true,
    "nickname": null,
  }
  let people : People = @json.from_json(object)
  @json.inspect(people, content={ "name": "Alice", "age": 25, "active": true })
}

///|
test "@json.get_nullable/invalid-type" {
  let object : Json = {
    "name": "Alice",
    "age": 25.0,
    "active": true,
    "nickname": 123.0,
  }
  let people : Result[People, @json.JsonDecodeError] = try? @json.from_json(
    object,
  )
  @json.inspect(people, content={
    "Err": [
      "JsonDecodeError",
      ["/nickname", "String::from_json: expected string"],
    ],
  })
}
