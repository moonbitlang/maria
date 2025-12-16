///|
struct ChatGenerationParamsPdf {
  engine : ChatGenerationParamsPdfEngine?
}

///|
pub impl ToJson for ChatGenerationParamsPdf with to_json(
  self : ChatGenerationParamsPdf,
) -> Json {
  let object : Map[String, Json] = {}
  if self.engine is Some(engine) {
    object["engine"] = engine.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ChatGenerationParamsPdf with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPdf raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPdf::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let engine : ChatGenerationParamsPdfEngine? = match object.get("engine") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("engine")))
  }
  ChatGenerationParamsPdf::{ engine, }
}
