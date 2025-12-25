///|
pub struct MessageDeveloper {
  content : MessageContent
  name : String?
}

///|
pub fn MessageDeveloper::new(
  content : MessageContent,
  name? : String,
) -> MessageDeveloper {
  MessageDeveloper::{ content, name }
}

///|
pub impl ToJson for MessageDeveloper with to_json(self : MessageDeveloper) -> Json {
  let object : Map[String, Json] = { "role": "developer" }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  object["content"] = self.content.to_json()
  Json::object(object)
}

///|
pub impl @json.FromJson for MessageDeveloper with from_json(
  json : Json,
  path : @json.JsonPath,
) -> MessageDeveloper raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.MessageDeveloper::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let content : MessageContent = match object.get("content") {
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
  MessageDeveloper::{ content, name }
}
