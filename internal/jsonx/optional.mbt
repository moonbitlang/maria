///|
/// Extracts and deserializes a nullable field from a JSON object.
///
/// Parameters:
///
/// * `object` : The JSON object to extract the field from.
/// * `key` : The name of the nullable field to extract.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the deserialized value of type `T` from the specified field if the
/// field is present and not `null`, `None` otherwise.
///
/// Throws an error of type `@json.JsonDecodeError` if the field is present but
/// deserialization fails.
pub fn[T : @json.FromJson] Object::optional(
  object : Object,
  key : String,
  path~ : @json.JsonPath,
) -> T? raise @json.JsonDecodeError {
  match object.get(key) {
    None | Some(Null) => None
    Some(value) => Some(@json.from_json(value, path=path.add_key(key)))
  }
}
