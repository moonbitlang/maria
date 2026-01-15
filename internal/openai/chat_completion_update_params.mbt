///|
pub struct ChatCompletionUpdateParams {
  metadata : Map[String, String]
}

///|
pub fn ChatCompletionUpdateParams::new(
  metadata? : Map[String, String] = {},
) -> ChatCompletionUpdateParams {
  { metadata, }
}

///|
pub impl ToJson for ChatCompletionUpdateParams with to_json(
  self : ChatCompletionUpdateParams,
) -> Json {
  let obj : Map[String, Json] = {}
  if !self.metadata.is_empty() {
    let metadata_obj : Map[String, Json] = {}
    for k, v in self.metadata {
      metadata_obj[k] = v.to_json()
    }
    obj["metadata"] = Json::object(metadata_obj)
  }
  Json::object(obj)
}
