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
pub fn ToolResult::ok(output : String) -> ToolResult {
  ToolResult::{ output, error: None }
}

///|
pub fn ToolResult::error(output : String) -> ToolResult {
  ToolResult::{ output, error: Some(Failure(output)) }
}

///|
pub fn ToolResult::new(output : String, error? : Error) -> ToolResult {
  ToolResult::{ output, error }
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
