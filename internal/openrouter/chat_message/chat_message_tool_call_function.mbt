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

///|
pub impl @json.FromJson for ChatMessageToolCallFunction with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatMessageToolCallFunction raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatMessageToolCallFunction::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let function_obj : Map[String, Json] = match object.get("function") {
    Some(Object(function_obj)) => function_obj
    Some(_) =>
      raise @json.JsonDecodeError(
        (path.add_key("function"), "\{func_name}: expect object"),
      )
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("function"), "\{func_name}: missing field function"),
      )
  }
  let name : String = match function_obj.get("name") {
    Some(name_json) =>
      @json.from_json(name_json, path=path.add_key("function").add_key("name"))
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("function").add_key("name"),
          "\{func_name}: missing field name",
        ),
      )
  }
  let arguments : String = match function_obj.get("arguments") {
    Some(arguments_json) =>
      @json.from_json(
        arguments_json,
        path=path.add_key("function").add_key("arguments"),
      )
    None =>
      raise @json.JsonDecodeError(
        (
          path.add_key("function").add_key("arguments"),
          "\{func_name}: missing field arguments",
        ),
      )
  }
  ChatMessageToolCallFunction::{ name, arguments }
}
