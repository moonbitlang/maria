///|
struct Schema0 {
  value : String
}

///|
pub impl ToJson for Schema0 with to_json(self : Schema0) -> Json {
  let object : Map[String, Json] = { "value": self.value.to_json() }
  Json::object(object)
}
