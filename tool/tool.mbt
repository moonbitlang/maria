///|
pub struct ToolDesc {
  description : String
  name : String
  parameters : Json
}

///|
pub struct Tool {
  desc : ToolDesc
  priv f : ToolFn
  render : async (Result) -> String noraise
}

///|
pub(all) struct ToolFn(async (Json) -> Result noraise)

///|
pub enum Result {
  Ok(Json)
  Error(Error, Json)
} derive(ToJson)

///|
pub fn ok(output : Json) -> Result {
  Ok(output)
}

///|
pub fn Result::output(self : Result) -> Json {
  match self {
    Ok(output) => output
    Error(_, output) => output
  }
}

///|
priv suberror ToolFailure Json derive(ToJson)

///|
pub fn error(output : Json, error? : Error = ToolFailure(output)) -> Result {
  Error(error, output)
}

///|
pub fn tool(
  description~ : String,
  name~ : String,
  parameters~ : Json,
  f : ToolFn,
  render~ : async (Result) -> String noraise,
) -> Tool {
  Tool::{ desc: { description, name, parameters }, f, render }
}

///|
pub async fn Tool::call(tool : Tool, args : Json) -> Result noraise {
  (tool.f)(args)
}
