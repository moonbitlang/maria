///|
#json.schema
priv struct Params {
  /// The content to write to the file.
  content : String
  /// The path of the file to write to, relative to the current working directory.
  path : String
  /// Optional separator to add between existing content and new content (default: newline).
  #json.default(string("\n"))
  separator : String?
} derive(ToJson, FromJson)
