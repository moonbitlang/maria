///|
/// Shared metadata map.
pub struct Metadata(Map[String, String])

///|
pub impl ToJson for Metadata with to_json(self : Metadata) -> Json {
  self.to_json()
}

///|
pub impl @json.FromJson for Metadata with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Metadata raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let metadata : Map[String, String] = {}
  for key, value in object {
    match value {
      String(text) => metadata[key] = text
      _ =>
        raise @json.JsonDecodeError(
          (path.add_key(key), "Metadata: expected string"),
        )
    }
  }
  metadata
}
