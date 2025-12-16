///|
struct ResponseFormatTextGrammar {
  grammar : String
}

///|
pub impl ToJson for ResponseFormatTextGrammar with to_json(
  self : ResponseFormatTextGrammar,
) -> Json {
  let object : Map[String, Json] = {
    "type": "text_grammar",
    "grammar": self.grammar.to_json(),
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ResponseFormatTextGrammar with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFormatTextGrammar raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ResponseFormatTextGrammar::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let grammar : String = match object.get("grammar") {
    Some(v) => @json.from_json(v, path=path.add_key("grammar"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("grammar"), "\{func_name}: missing field grammar"),
      )
  }
  ResponseFormatTextGrammar::{ grammar, }
}
