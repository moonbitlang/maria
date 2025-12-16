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
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let age : Int = object.required("age", path~)
  let active : Bool = object.required("active", path~)
  let nickname : String? = object.optional("nickname", path~)
  People::{ name, age, active, nickname }
}

///|
test "@jsonx.Object::required" {
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
test "@jsonx.Object::required/missing-field" {
  let object : Json = { "name": "Bob" }
  let people : Result[People, @json.JsonDecodeError] = try? @json.from_json(
    object,
  )
  @json.inspect(people, content={
    "Err": ["JsonDecodeError", ["/age", "field 'age' is required"]],
  })
}

///|
test "@jsonx.Object::optional/not-present" {
  let object : Json = { "name": "Alice", "age": 25.0, "active": true }
  let people : People = @json.from_json(object)
  @json.inspect(people, content={ "name": "Alice", "age": 25, "active": true })
}

///|
test "@jsonx.Object::optional/explicit-null" {
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
test "@jsonx.Object::optional/invalid-type" {
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
