///|
/// Extracts and deserializes a required field from a JSON object.
///
/// Parameters:
///
/// * `object` : The JSON object to extract the field from.
/// * `key` : The name of the required field to extract.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the deserialized value of type `T` from the specified field.
///
/// Throws an error of type `@json.JsonDecodeError` if the field is missing from
/// the object or if deserialization fails.
pub fn[T : @json.FromJson] Object::required(
  object : Object,
  key : String,
  path~ : @json.JsonPath,
) -> T raise @json.JsonDecodeError {
  match object.get(key) {
    Some(value) => @json.from_json(value, path~)
    None =>
      raise @json.JsonDecodeError(
        (path.add_key(key), "field '\{key}' is required"),
      )
  }
}
