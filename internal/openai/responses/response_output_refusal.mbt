///|
/// A refusal from the model.
struct ResponseOutputRefusal {
  /// The refusal explanation from the model.
  refusal : String
}

///|
pub impl ToJson for ResponseOutputRefusal with to_json(
  self : ResponseOutputRefusal,
) -> Json {
  { "type": "refusal", "refusal": self.refusal }
}

///|
pub impl @json.FromJson for ResponseOutputRefusal with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputRefusal raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let refusal : String = object.required("refusal", path~)
  ResponseOutputRefusal::{ refusal, }
}
