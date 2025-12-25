///|
struct Debug {
  echo_upstream_body : Bool?
}

///|
pub impl ToJson for Debug with to_json(self : Debug) -> Json {
  let object : Map[String, Json] = {}
  if self.echo_upstream_body is Some(echo_upstream_body) {
    object["echo_upstream_body"] = echo_upstream_body.to_json()
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for Debug with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Debug raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.Debug::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let echo_upstream_body : Bool? = match object.get("echo_upstream_body") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("echo_upstream_body")))
  }
  Debug::{ echo_upstream_body, }
}
