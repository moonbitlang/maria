///|
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
pub fn Header::new() -> Header {
  Header({})
}

///|
pub fn Header::set(self : Header, key : String, value : String) -> Unit {
  self.0[key] = value
}

///|
pub fn Header::config(self : Header, config : Map[String, String]) -> Unit {
  self.0.merge_in_place(config)
}

///|
pub fn Header::add(self : Header, key : String, value : String) -> Unit {
  match self.0.get(key) {
    Some(existing) => self.0[key] = "\{existing}, \{value}"
    None => self.0[key] = value
  }
}
