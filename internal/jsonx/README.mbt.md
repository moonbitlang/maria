# internal/jsonx

This package provides utility functions for working with JSON in MoonBit, particularly focused on improving error handling when deserializing JSON objects.

## Overview

The main functionality provided by this package is the `get_required_field` function, which extracts and deserializes a required field from a JSON object with proper error reporting using JSON paths.

## Usage

### Extracting Required Fields

Use `get_required_field` to extract and deserialize required fields from JSON objects with automatic error reporting:

```moonbit
let json_obj : Map[String, Json] = // ... parse some JSON
let name : String = get_required_field(json_obj, "name", path=root_path)
let age : Int = get_required_field(json_obj, "age", path=root_path)
```

If a field is missing or deserialization fails, you'll get a `JsonDecodeError` with a proper path indicating exactly where the error occurred (e.g., `$.name` or `$.age`).

### Building Nested Paths

The path can be extended as you traverse nested structures:

```moonbit
fn parse_user(json : Json, path : @json.JsonPath) -> User!JsonDecodeError {
  let obj = @json.as_object(json)!
  let address_json = get_required_field(obj, "address", path)
  let address = parse_address(address_json, path.add_key("address"))!
  // ... parse other fields
}
```

This will produce error messages like `$.address.street` if something goes wrong in the nested structure.

## API Reference

### `get_required_field`

```moonbit
pub fn[T : @json.FromJson] get_required_field(
  object : Map[String, Json],
  key : String,
  path? : @json.JsonPath = root_path,
) -> T raise @json.JsonDecodeError
```

Extracts and deserializes a required field from a JSON object.

**Parameters:**

- `object`: The JSON object to extract the field from
- `key`: The name of the required field to extract
- `path`: The current JSON path for error reporting context (defaults to `root_path`)

**Returns:** The deserialized value of type `T`

**Raises:** `@json.JsonDecodeError` if the field is missing or deserialization fails

### `root_path`

```moonbit
pub let root_path : @json.JsonPath
```

The root JSON path for error reporting. Use this as the starting point when calling `get_required_field` and similar functions.

Due to the abstract visibility of `JsonPath`, this is obtained through the indirect method described above.
