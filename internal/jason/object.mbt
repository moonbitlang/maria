///|
pub(all) struct Object(Map[String, Jason])

///|
pub fn Object::from_map(value : Map[String, &ToJason]) -> Object {
  let object = Map::new()
  for k, v in value {
    object[k] = v.to_jason()
  }
  Object(object)
}

///|
pub fn Object::get(self : Object, key : String) -> Jason? {
  self.0.get(key)
}

///|
pub fn Object::iterator2(self : Object) -> Iterator2[String, Jason] {
  self.0.iterator2()
}

///|
/// Extracts and converts a JSON value to an Object type.
///
/// Parameters:
///
/// * `jason` : The JSON value to convert to an Object.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the extracted Object.
///
/// Throws an error of type `DecodeError` if the JSON value is not an Object
/// type.
pub fn Jason::as_object(
  jason : Jason,
  path~ : JasonPath,
) -> Object raise DecodeError {
  guard jason is Object(object) else {
    raise DecodeError::TypeMismatch(
      path,
      expect=[JasonType::Object],
      actual=jason,
    )
  }
  object
}

///|
/// Extracts and deserializes a required field from a JSON object.
///
/// Parameters:
///
/// * `object` : The JSON object to extract the field from.
/// * `key` : The name of the required field to extract.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the deserialized value of type `T` from the specified field.
///
/// Throws an error of type `@json.JsonDecodeError` if the field is missing from
/// the object or if deserialization fails.
pub fn[T : FromJason] Object::required(
  object : Object,
  key : String,
  path~ : JasonPath,
) -> T raise DecodeError {
  match object.get(key) {
    Some(value) => from_jason(value, path=path.add_key(key))
    None => raise MissingField(path.add_key(key))
  }
}

///|
/// Extracts and deserializes a nullable field from a JSON object.
///
/// Parameters:
///
/// * `object` : The JSON object to extract the field from.
/// * `key` : The name of the nullable field to extract.
/// * `path` : The current JSON path for error reporting context.
///
/// Returns the deserialized value of type `T` from the specified field if the
/// field is present and not `null`, `None` otherwise.
///
/// Throws an error of type `DecodeError` if the field is present but
/// deserialization fails.
pub fn[T : FromJason] Object::optional(
  object : Object,
  key : String,
  path~ : JasonPath,
) -> T? raise DecodeError {
  match object.get(key) {
    None | Some(Null) => None
    Some(value) => Some(from_jason(value, path=path.add_key(key)))
  }
}

///|
struct ObjectBuilder(Map[String, Jason])

///|
pub fn ObjectBuilder::new() -> ObjectBuilder {
  ObjectBuilder(Map::new())
}

///|
/// Adds an optional field to the object being built, only including it if the
/// value is present.
///
/// Parameters:
///
/// * `self` : The object builder to add the field to.
/// * `key` : The field name to add to the object.
/// * `value` : The optional value to associate with the field. If `None`, the
///   field will not be added to the object. If `Some(value)`, the value will be
///   serialized using the `ToJason` trait and added to the object.
pub fn[T : ToJason] ObjectBuilder::optional(
  self : ObjectBuilder,
  key : String,
  value : T?,
) -> Unit {
  if value is Some(value) {
    self.0[key] = value.to_jason()
  }
}

///|
/// Adds a field with the given key and value to the object being built.
///
/// Parameters:
///
/// * `self` : The object builder to add the field to.
/// * `key` : The field name to add to the object.
/// * `value` : The value to associate with the field, which must implement the
///   `ToJason` trait.
pub fn[T : ToJason] ObjectBuilder::required(
  self : ObjectBuilder,
  key : String,
  value : T,
) -> Unit {
  self.0[key] = value.to_jason()
}

///|
/// Converts the object builder to a finalized `Object`.
///
/// Parameters:
///
/// * `self` : The object builder to finalize.
///
/// Returns the constructed `Object` containing all the fields that were added
/// to the builder.
pub fn ObjectBuilder::finalize(self : ObjectBuilder) -> Object {
  Object(self.0)
}
