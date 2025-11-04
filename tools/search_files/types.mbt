///|
#json.schema
priv struct Params {
  /// The kind of search to perform. 
  /// 'regex' performs traditional regex-based file content search. 
  /// 'moonbit_definition' performs fuzzy symbolic search to find MoonBit symbol definitions 
  /// - note that when using 'moonbit_definition', 
  /// the regex parameter can be imprecise as the system will perform fuzzy search 
  /// to find the most relevant symbols. 'moonbit_references' finds all references 
  /// to a MoonBit symbol using the moon IDE tool.",
  #json.enumerate(string("regex", "moonbit_definition", "moonbit_references"))
  kind : String
  /// The path of the directory or file to search in, relative to the current working directory.
  path : String
  /// Glob pattern to filter files (e.g., '*.ts', '*.js', '*.py', etc.). Defaults to '*' to search all files.
  #json.default(string("*"))
  file_pattern : String?
  /// Number of context lines to show before and after each match. Defaults to 2.
  #json.default(integer("2"))
  context_lines : Int?
  /// The search pattern. 
  /// For 'regex' kind: regular expression pattern with full regex syntax. 
  /// For 'moonbit_definition' kind: symbol name or partial name (can be imprecise) for fuzzy symbolic search.
  regex : String
}

///|
let schema : @tool.JsonSchema = @tool.JsonSchema::from_json(
  Params::get_schema(),
)
