///|
/// Mutable HTTP header collection.
///
/// `Header` stores header names and values as strings and provides helpers
/// for setting, merging and appending values.
struct Header(Map[String, String])

///|
pub impl ToJson for Header with to_json(self : Header) -> Json {
  self.0.to_json()
}

///|
pub impl Show for Header with output(self : Header, logger : &Logger) -> Unit {
  self.0.output(logger)
}

///|
/// Creates an empty header map.
pub fn Header::new() -> Header {
  Header({})
}

///|
/// Sets a header to the given value, replacing any existing value.
pub fn Header::set(self : Header, key : String, value : String) -> Unit {
  self.0[key] = value
}

///|
/// Merges a map of headers into this header collection.
///
/// Existing keys are overwritten by the values from `config`.
pub fn Header::config(self : Header, config : Map[String, String]) -> Unit {
  self.0.merge_in_place(config)
}

///|
/// Adds a value to a potentially multi-valued header.
///
/// If the header already exists, the new value is appended using
/// `", "` as a separator, otherwise it is set as-is.
pub fn Header::add(self : Header, key : String, value : String) -> Unit {
  match self.0.get(key) {
    Some(existing) => self.0[key] = "\{existing}, \{value}"
    None => self.0[key] = value
  }
}
