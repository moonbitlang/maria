///|
/// Schema definition for JSON responses.
struct JsonSchema {
  name : String
  description : String?
  schema : Map[String, Json]
  strict : Bool?
}
