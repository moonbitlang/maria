///|
/// A file input to the model.
pub struct ResponseInputFile {
  file_data : String?
  file_id : String?
  file_url : String?
  filename : String?
}

///|
pub impl ToJson for ResponseInputFile with to_json(self : ResponseInputFile) -> Json {
  let obj : Map[String, Json] = { "type": "input_file" }
  if self.file_data is Some(file_data) {
    obj["file_data"] = file_data.to_json()
  }
  if self.file_id is Some(file_id) {
    obj["file_id"] = file_id.to_json()
  }
  if self.file_url is Some(file_url) {
    obj["file_url"] = file_url.to_json()
  }
  if self.filename is Some(filename) {
    obj["filename"] = filename.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputFile with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputFile raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let file_data : String? = object.optional("file_data", path~)
  let file_id : String? = object.optional("file_id", path~)
  let file_url : String? = object.optional("file_url", path~)
  let filename : String? = object.optional("filename", path~)
  ResponseInputFile::{ file_data, file_id, file_url, filename }
}
