///|
#json.generated
fn Params::get_schema() -> Json {
  {
    "type": "object",
    "required": ["kind", "path", "regex"],
    "properties": {
      "kind": {
        "type": "string",
        "enum": ["regex", "moonbit_definition", "moonbit_references"],
        "description": "The kind of search to perform. \n'regex' performs traditional regex-based file content search. \n'moonbit_definition' performs fuzzy symbolic search to find MoonBit symbol definitions \n- note that when using 'moonbit_definition', \nthe regex parameter can be imprecise as the system will perform fuzzy search \nto find the most relevant symbols. 'moonbit_references' finds all references \nto a MoonBit symbol using the moon IDE tool.\",",
      },
      "path": {
        "type": "string",
        "description": "The path of the directory or file to search in, relative to the current working directory.",
      },
      "file_pattern": {
        "type": "string",
        "default": "*",
        "description": "Glob pattern to filter files (e.g., '*.ts', '*.js', '*.py', etc.). Defaults to '*' to search all files.",
      },
      "context_lines": {
        "type": "integer",
        "default": 2,
        "description": "Number of context lines to show before and after each match. Defaults to 2.",
      },
      "regex": {
        "type": "string",
        "description": "The search pattern. \nFor 'regex' kind: regular expression pattern with full regex syntax. \nFor 'moonbit_definition' kind: symbol name or partial name (can be imprecise) for fuzzy symbolic search.",
      },
    },
  }
}
