///|
/// Schema definition for JSON responses.
pub(all) struct JsonSchema {
  name : String
  description : String?
  schema : Map[String, Json]
  strict : Bool?
}
