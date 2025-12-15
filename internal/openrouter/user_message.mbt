///|
struct UserMessage {
  content : UserMessageContent
  name : String?
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
