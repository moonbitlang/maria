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
