///|
test {
  let source =
    #|///|
    #|/// doc for pos
    #|#json.schema
    #|struct Pos {
    #|  #json.enumerate(string("a", "b", "c"))
    #|  v : String
    #|  w : Array[Int]
    #|  /// doc for x
    #|  /// doc2
    #|  #json.default(string("*"))
    #|  x : String?
    #|  /// doc for y
    #|  #json.default(boolean(false))
    #|  y : Bool?
    #|  /// doc for z
    #|  z : Int?
    #|}
  let (ast, _) = @parser.parse_string(source)
  let ast = derive_json_schema(ast)
  let result = @formatter.impls_to_string(ast)
  inspect(
    result,
    content=(
      #|///|
      #|#json.generated
      #|pub fn Pos::get_schema() -> Json {
      #|  {
      #|    "type": "object",
      #|    "properties": {
      #|      "v": { "type": "string", "enum": ["a", "b", "c"] },
      #|      "w": { "type": "array", "items": { "type": "integer" } },
      #|      "x": {
      #|        "type": "string",
      #|        "description": "doc for x\ndoc2",
      #|        "default": "*",
      #|      },
      #|      "y": { "type": "boolean", "description": "doc for y", "default": false },
      #|      "z": { "type": "integer", "description": "doc for z" },
      #|    },
      #|    "required": ["v", "w"],
      #|  }
      #|}
      #|
      #|
    ),
  )
}

///|
test "panic - invalid T with default" {
  let source =
    #|#json.schema
    #|struct Pos {
    #|  #json.default(integer("10"))
    #|  w : Int
    #|}
  let (ast, _) = @parser.parse_string(source)
  let _ = derive_json_schema(ast)

}

///|
test "panic - invalid nested option" {
  let source =
    #|#json.schema
    #|struct Pos {
    #|  w : Int??
    #|}
  let (ast, _) = @parser.parse_string(source)
  let _ = derive_json_schema(ast)

}

///|
test "array with nullable" {
  let source =
    #|#json.schema
    #|struct Pos {
    #|  w : Array[Int?]
    #|}
  let (ast, _) = @parser.parse_string(source)
  let ast = derive_json_schema(ast)
  let result = @formatter.impls_to_string(ast)
  inspect(
    result,
    content=(
      #|///|
      #|#json.generated
      #|pub fn Pos::get_schema() -> Json {
      #|  {
      #|    "type": "object",
      #|    "properties": {
      #|      "w": { "type": "array", "items": { "type": ["integer", "null"] } },
      #|    },
      #|    "required": ["w"],
      #|  }
      #|}
      #|
      #|
    ),
  )
}
