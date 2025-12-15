///|
struct MessageDeveloper {
  content : MessageContent
  name : String?
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
