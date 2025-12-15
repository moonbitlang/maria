///|
struct ChatMessageToolCallFunction {
  name : String
  arguments : String
}

///|
pub impl ToJson for ChatMessageToolCallFunction with to_json(
  self : ChatMessageToolCallFunction,
) -> Json {
  let object : Map[String, Json] = {
    "type": "function",
    "function": {
      "name": self.name.to_json(),
      "arguments": self.arguments.to_json(),
    },
  }
  Json::object(object)
}
