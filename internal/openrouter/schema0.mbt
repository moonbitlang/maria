///|
struct Schema0 {
  value : String
}

///|
pub impl ToJson for Schema0 with to_json(self : Schema0) -> Json {
  let object : Map[String, Json] = { "value": self.value.to_json() }
  Json::object(object)
}

///|
pub impl @json.FromJson for Schema0 with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Schema0 raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Schema0::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let value : String = match object.get("value") {
    Some(v) => @json.from_json(v, path=path.add_key("value"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("value"), "\{func_name}: missing field value"),
      )
  }
  Schema0::{ value, }
}
