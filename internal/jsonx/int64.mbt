///|
/// Converts an `Int64` value to a JSON number representation.
///
/// Parameters:
///
/// * `value` : The 64-bit integer to convert to JSON.
///
/// Returns a `Json` value representing the integer as a JSON number.
///
/// Note: The numeric value is stored as a `Double` and may lose precision for
/// `Int64` values outside the range ±2^53 (approximately
/// ±9007199254740992). For such large integers, the `Double` value itself is
/// imprecise; the exact value is preserved only in the `repr` string
/// representation. Deserializers that need full `Int64` precision must use the
/// `repr` field (as done by `as_int64`) rather than relying solely on the
/// `Double` value.
pub fn int64(value : Int64) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
/// Converts a JSON value to an Int64, handling both numeric and string
/// representations.
///
/// Parameters:
///
/// * `json` : The JSON value to convert to an Int64.
/// * `path` : The JSON path for error reporting context.
///
/// Returns the Int64 value extracted from the JSON.
///
/// Throws an error of type `@json.JsonDecodeError` if the JSON value is not a
/// number or if the string representation cannot be parsed as an Int64.
pub fn as_int64(
  json : Json,
  path~ : @json.JsonPath,
) -> Int64 raise @json.JsonDecodeError {
  match json {
    Number(number, repr=None) => number.to_int64()
    Number(_, repr=Some(str)) =>
      @strconv.parse_int64(str) catch {
        error =>
          raise @json.JsonDecodeError(
            (path, "Int64::as_int64: parsing failure \{error}"),
          )
      }
    _ => raise @json.JsonDecodeError((path, "Int64::as_int64: expected number"))
  }
}

///|
/// Extracts and deserializes a required Int64 field from a JSON object.
///
/// Parameters:
///
/// * `object` : The JSON object to extract the field from.
/// * `key` : The name of the required Int64 field to extract.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the Int64 value from the specified field, properly handling JSON
/// numbers with string representation for precision.
///
/// Throws an error of type `@json.JsonDecodeError` if the field is missing from
/// the object or if the value cannot be parsed as an Int64.
pub fn Object::required_int64(
  object : Object,
  key : String,
  path~ : @json.JsonPath,
) -> Int64 raise @json.JsonDecodeError {
  match object.get(key) {
    Some(value) => as_int64(value, path=path.add_key(key))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key(key), "field '\{key}' is required"),
      )
  }
}

///|
/// Extracts and deserializes an optional Int64 field from a JSON object.
///
/// Parameters:
///
/// * `object` : The JSON object to extract the field from.
/// * `key` : The name of the optional Int64 field to extract.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the Int64 value from the specified field if the field is present and
/// not `null`, `None` otherwise. Properly handles JSON numbers with string
/// representation for precision.
///
/// Throws an error of type `@json.JsonDecodeError` if the field is present but
/// the value cannot be parsed as an Int64.
pub fn Object::optional_int64(
  object : Object,
  key : String,
  path~ : @json.JsonPath,
) -> Int64? raise @json.JsonDecodeError {
  match object.get(key) {
    Some(Null) | None => None
    Some(value) => Some(as_int64(value, path=path.add_key(key)))
  }
}
