///|
pub struct Tool {
  description : String
  name : String
  parameters : Map[String, Json]
  f : async (Json, ToolContext) -> ToolResult noraise
}

///|
pub struct ToolResult {
  output : String
  error : Error?
}

///|
pub fn ok(output : String) -> ToolResult {
  ToolResult::{ output, error: None }
}

///|
pub fn error(
  output : String,
  error? : Error = Failure(output),
) -> ToolResult {
  ToolResult::{ output, error: Some(error) }
}

///|
pub fn Tool::new(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
  f : async (Json, ToolContext) -> ToolResult noraise,
) -> Tool {
  Tool::{ description, name, parameters, f }
}

///|
pub struct ToolContext {
  cwd : String
}

///|
pub fn ToolContext::new(cwd~ : String) -> ToolContext {
  ToolContext::{ cwd, }
}
