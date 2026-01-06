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

///|
/// Returns an iterator over the key-value pairs in the JSON object.
///
/// Parameters:
///
/// * `self` : The JSON object to iterate over.
///
/// Returns an `Iter2[String, Json]` that yields each key-value pair in the
/// object, where keys are strings and values are JSON values.
pub fn Object::iter2(self : Object) -> Iter2[String, Json] {
  self.0.iter2()
}
