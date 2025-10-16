///|
/// Position information for error reporting
pub(all) struct Position {
  line : Int
  column : Int
} derive(Show, Eq, ToJson)

///|
/// TOML values representation
pub enum TomlValue {
  String(String)
  Integer(Int64)
  Float(Double)
  Boolean(Bool)
  Array(Array[TomlValue])
  Table(Map[String, TomlValue])
} derive(Show, Eq, ToJson)

///|
/// TOML table type alias for convenience
pub typealias Map[String, TomlValue] as TomlTable

///|
/// TOML document represents the top-level structure
pub(all) struct TomlDocument {
  root : TomlTable
} derive(Show, Eq, ToJson)

///|
/// Check if value is a string
pub fn TomlValue::is_string(self : TomlValue) -> Bool {
  match self {
    String(_) => true
    _ => false
  }
}

///|
/// Get string value if it is a string
pub fn TomlValue::as_string(self : TomlValue) -> String? {
  match self {
    String(s) => Some(s)
    _ => None
  }
}

///|
/// Get integer value if it is an integer
pub fn TomlValue::as_integer(self : TomlValue) -> Int64? {
  match self {
    Integer(i) => Some(i)
    _ => None
  }
}

///|
/// Get table value if it is a table
pub fn TomlValue::as_table(self : TomlValue) -> TomlTable? {
  match self {
    Table(table) => Some(table)
    _ => None
  }
}

///|
/// Create a new empty TOML document
pub fn TomlDocument::new() -> TomlDocument {
  TomlDocument::{ root: Map::new() }
}

///|
/// Get a value from the document by key
pub fn TomlDocument::get(self : TomlDocument, key : String) -> TomlValue? {
  self.root.get(key)
}
