///|
pub fn int64(value : Int64) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
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
/// This function properly handles JSON numbers (not strings) for Int64 values.
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
/// This function properly handles JSON numbers (not strings) for Int64 values.
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
