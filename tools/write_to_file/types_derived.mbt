///|
#json.generated
fn Params::get_schema() -> Json {
  {
    "type": "object",
    "required": ["content", "path"],
    "properties": {
      "content": {
        "type": "string",
        "description": "The content to write to the file.",
      },
      "path": {
        "type": "string",
        "description": "The path of the file to write to, relative to the current working directory.",
      },
      "separator": {
        "type": "string",
        "default": "\n",
        "description": "Optional separator to add between existing content and new content (default: newline).",
      },
    },
  }
}
