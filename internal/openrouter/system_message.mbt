///|
struct SystemMessage {
  content : SystemMessageContent
  name : String?
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
