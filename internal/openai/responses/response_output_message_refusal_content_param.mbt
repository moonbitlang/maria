///|
/// A refusal from the model.
struct ResponseOutputMessageRefusalContentParam {
  /// The refusal explanation from the model.
  refusal : String
} derive(Show)

///|
pub impl ToJson for ResponseOutputMessageRefusalContentParam with to_json(
  self : ResponseOutputMessageRefusalContentParam,
) -> Json {
  { "type": "refusal", "refusal": self.refusal }
}

///|
pub impl @json.FromJson for ResponseOutputMessageRefusalContentParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputMessageRefusalContentParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let refusal : String = object.required("refusal", path~)
  ResponseOutputMessageRefusalContentParam::{ refusal, }
}
