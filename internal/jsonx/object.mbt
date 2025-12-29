///|
pub(all) struct Object(Map[String, Json])

///|
pub fn Object::get(self : Object, key : String) -> Json? {
  self.0.get(key)
}

///|
pub fn as_object(
  json : Json,
  path~ : @json.JsonPath,
) -> Object raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  Object(obj)
}
