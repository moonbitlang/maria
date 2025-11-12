///|
#json.schema
priv struct Input {
  /// The path of the file to write to, relative to the current working directory.
  path : String
  /// The content to replace with. If search is not provided, this will be the entire file content. 
  /// If replace is not provided, the matched content will be deleted.
  replace : String
  /// The content to search for. If not provided, the entire file will be replaced with the replace content.
  search : String?
} derive(FromJson, ToJson)

///|
/// The schema for the replace_in_file tool, coupled with the Input struct below.
let schema : @tool.JsonSchema = @tool.JsonSchema::from_json(Input::get_schema())

///|
test "Input FromJson/ToJson" {
  let json_input : Array[Json] = [
    { "path": "example.txt", "replace": "new content", "search": "old content" },
    { "path": "example.txt", "replace": "new content" },
  ]
  fn round_trip(x : Json) raise {
    let input : Input = @json.from_json(x)
    input.to_json()
  }

  @json.inspect(json_input.map(round_trip), content=[
    { "path": "example.txt", "replace": "new content", "search": "old content" },
    { "path": "example.txt", "replace": "new content" },
  ])
}
