///|
#json.generated
pub fn Input::get_schema() -> Json {
  {
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The path of the file to write to, relative to the current working directory.",
      },
      "replace": {
        "type": "string",
        "description": "The content to replace with. If search is not provided, this will be the entire file content. If replace is not provided, the matched content will be deleted.",
      },
      "search": {
        "type": "string",
        "description": "The content to search for. If not provided, the entire file will be replaced with the replace content.",
      },
    },
    "required": ["path", "replace"],
  }
}

