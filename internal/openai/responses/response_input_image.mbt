///|
/// The detail level of the image to be sent to the model.
pub enum ResponseInputImageDetail {
  Low
  High
  Auto
}

///|
pub impl ToJson for ResponseInputImageDetail with to_json(
  self : ResponseInputImageDetail,
) -> Json {
  match self {
    Low => "low"
    High => "high"
    Auto => "auto"
  }
}

///|
pub impl @json.FromJson for ResponseInputImageDetail with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputImageDetail raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ResponseInputImageDetail: expected string"),
    )
  }
  match value {
    "low" => Low
    "high" => High
    "auto" => Auto
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseInputImageDetail: invalid value '\{value}'"),
      )
  }
}

///|
/// An image input to the model.
pub struct ResponseInputImage {
  detail : ResponseInputImageDetail
  file_id : String?
  image_url : String?
}

///|
pub impl ToJson for ResponseInputImage with to_json(self : ResponseInputImage) -> Json {
  let obj : Map[String, Json] = { "detail": self.detail, "type": "input_image" }
  if self.file_id is Some(file_id) {
    obj["file_id"] = file_id.to_json()
  }
  if self.image_url is Some(image_url) {
    obj["image_url"] = image_url.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputImage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputImage raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let detail : ResponseInputImageDetail = object.required("detail", path~)
  let _ : String = object.required("type", path~)
  let file_id : String? = object.optional("file_id", path~)
  let image_url : String? = object.optional("image_url", path~)
  ResponseInputImage::{ detail, file_id, image_url }
}
