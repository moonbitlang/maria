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
