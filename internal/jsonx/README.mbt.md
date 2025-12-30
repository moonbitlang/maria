# internal/jsonx

This package provides small helpers to decode JSON objects with accurate
`@json.JsonDecodeError` paths. It wraps JSON objects in `@jsonx.Object` and
offers `required` and `optional` field accessors that add the key to the path
before decoding.

## Overview

- `as_object` converts a `Json` value into `@jsonx.Object` with path-aware error
  reporting.
- `Object::required` extracts a required field and decodes it.
- `Object::optional` extracts an optional field and decodes it when present and
  non-null.

## Usage

### Extracting Required and Optional Fields

```moonbit
///|
fn parse_user(
  json : Json,
  path : @json.JsonPath,
) -> User raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let age : Int = object.required("age", path~)
  let nickname : String? = object.optional("nickname", path~)
  User::{ name, age, nickname }
}
```

If a field is missing or decoding fails, the error carries the full JSON path,
for example `/age` or `/nickname`.

### Nested Objects

```moonbit
///|
fn parse_profile(
  json : Json,
  path : @json.JsonPath,
) -> Profile raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let address_json : Json = object.required("address", path~)
  let address = parse_address(address_json, path.add_key("address"))
  Profile::{ address, }
}
```

## API Reference

### `@jsonx.Object`

```moonbit
///|
pub(all) struct Object(Map[String, Json])
```

### `as_object`

```moonbit
pub fn as_object(
  json : Json,
  path~ : @json.JsonPath,
) -> Object raise @json.JsonDecodeError
```

### `Object::required`

```moonbit
pub fn[T : @json.FromJson] Object::required(
  object : Object,
  key : String,
  path~ : @json.JsonPath,
) -> T raise @json.JsonDecodeError
```

### `Object::optional`

```moonbit
pub fn[T : @json.FromJson] Object::optional(
  object : Object,
  key : String,
  path~ : @json.JsonPath,
) -> T? raise @json.JsonDecodeError
```
