///|
pub struct SystemMessage {
  content : SystemMessageContent
  name : String?
}

///|
pub fn SystemMessage::new(content : String, name? : String) -> SystemMessage {
  SystemMessage::{ content: SystemMessageContent::Text(content), name }
}

///|
pub impl ToJson for SystemMessage with to_json(self : SystemMessage) -> Json {
  let object : Map[String, Json] = { "role": "system" }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  object["content"] = self.content.to_json()
  Json::object(object)
}

///|
pub impl @json.FromJson for SystemMessage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> SystemMessage raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.SystemMessage::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let content : SystemMessageContent = match object.get("content") {
    Some(content_json) =>
      @json.from_json(content_json, path=path.add_key("content"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("content"), "\{func_name}: missing field content"),
      )
  }
  let name : String? = match object.get("name") {
    None | Some(Null) => None
    Some(name_json) =>
      Some(@json.from_json(name_json, path=path.add_key("name")))
  }
  SystemMessage::{ content, name }
}
