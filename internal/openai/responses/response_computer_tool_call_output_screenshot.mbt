///|
/// A computer screenshot image used with the computer use tool.
pub struct ResponseComputerToolCallOutputScreenshot {
  file_id : String?
  image_url : String?
}

///|
pub impl ToJson for ResponseComputerToolCallOutputScreenshot with to_json(
  self : ResponseComputerToolCallOutputScreenshot,
) -> Json {
  let obj : Map[String, Json] = { "type": "computer_screenshot" }
  if self.file_id is Some(file_id) {
    obj["file_id"] = file_id.to_json()
  }
  if self.image_url is Some(image_url) {
    obj["image_url"] = image_url.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseComputerToolCallOutputScreenshot with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseComputerToolCallOutputScreenshot raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let file_id : String? = object.optional("file_id", path~)
  let image_url : String? = object.optional("image_url", path~)
  ResponseComputerToolCallOutputScreenshot::{ file_id, image_url }
}
