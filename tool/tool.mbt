///|
pub struct Tool {
  description : String
  name : String
  parameters : Map[String, Json]
  f : async (Json, Context) -> Result noraise
}

///|
pub struct Result {
  output : String
  error : Error?
} derive(ToJson)

///|
pub fn ok(output : String) -> Result {
  Result::{ output, error: None }
}

///|
pub fn error(
  output : String,
  error? : Error = Failure(output),
) -> Result {
  Result::{ output, error: Some(error) }
}

///|
pub fn tool(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
  f : async (Json, Context) -> Result noraise,
) -> Tool {
  Tool::{ description, name, parameters, f }
}

///|
pub struct Context {
  cwd : String
}

///|
pub fn context(cwd~ : String) -> Context {
  Context::{ cwd, }
}
