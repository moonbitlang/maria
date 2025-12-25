///|
pub struct UserMessage {
  content : UserMessageContent
  name : String?
}

///|
pub fn[T : ToUserMessageContent] UserMessage::new(
  content : T,
  name? : String,
) -> UserMessage {
  UserMessage::{ content: content.to_user_message_content(), name }
}

///|
pub impl ToJson for UserMessage with to_json(self : UserMessage) -> Json {
  let object : Map[String, Json] = { "role": "user" }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  object["content"] = self.content.to_json()
  Json::object(object)
}

///|
pub impl @json.FromJson for UserMessage with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> UserMessage raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.UserMessage::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((json_path, "\{func_name}: expect object"))
  }
  let content : UserMessageContent = match object.get("content") {
    Some(content_json) =>
      @json.from_json(content_json, path=json_path.add_key("content"))
    None =>
      raise @json.JsonDecodeError(
        (
          json_path.add_key("content"),
          "\{func_name}: missing required field 'content'",
        ),
      )
  }
  let name : String? = match object.get("name") {
    None | Some(Null) => None
    Some(name_json) =>
      Some(@json.from_json(name_json, path=json_path.add_key("name")))
  }
  UserMessage::{ content, name }
}
