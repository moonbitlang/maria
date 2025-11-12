///|
#json.generated
fn FileContent::get_schema() -> Json {
  {
    "type": "object",
    "required": ["path"],
    "properties": {
      "path": { "type": "string" },
      "start_line": { "type": "integer" },
      "end_line": { "type": "integer" },
    },
  }
}

///|
#json.generated
fn Arguments::get_schema() -> Json {
  {
    "type": "object",
    "required": ["files"],
    "properties": {
      "files": {
        "type": "array",
        "items": { "$ref": "#/definitions/FileContent" },
      },
    },
    "definitions": { "FileContent": FileContent::get_schema() },
  }
}
