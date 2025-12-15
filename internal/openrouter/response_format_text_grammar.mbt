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
