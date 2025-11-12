///|
#json.schema
priv struct FileContent {
  path : String
  start_line : Int?
  end_line : Int?
}

///|
#json.schema
priv struct Arguments {
  files : Array[FileContent]
}

///|
let schema : @tool.JsonSchema = @tool.JsonSchema::from_json(
  FileContent::get_schema(),
)
