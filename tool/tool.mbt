///|
pub struct ToolDesc {
  description : String
  name : String
  parameters : Json
}

///|
pub struct Tool[Output] {
  desc : ToolDesc
  priv f : ToolFn[Output]
}

///|
pub(all) struct ToolFn[Output](async (Json) -> Result[Output] noraise)

///|
pub enum Result[Output] {
  Ok(Output)
  Error(Error, String)
} derive(ToJson)

///|
pub fn[Output] ok(output : Output) -> Result[Output] {
  Ok(output)
}

///|
pub fn[Output] Result::output(self : Result[Output]) -> Output raise {
  match self {
    Ok(output) => output
    Error(error, _) => raise error
  }
}

///|
pub impl[Output : Show] Show for Result[Output] with output(
  self : Result[Output],
  logger : &Logger,
) -> Unit {
  match self {
    Ok(output) => logger.write_string(output.to_string())
    Error(ToolFailure(_), message) => logger.write_string(message)
    Error(error, message) =>
      logger.write_string("\{message}\n\{error.to_json().stringify(indent=2)}")
  }
}

///|
priv suberror ToolFailure String derive(ToJson)

///|
pub fn[Output] error(
  output : String,
  error? : Error = ToolFailure(output),
) -> Result[Output] {
  Error(error, output)
}

///|
pub fn[Output] tool(
  description~ : String,
  name~ : String,
  parameters~ : Json,
  f : ToolFn[Output],
) -> Tool[Output] {
  Tool::{ desc: { description, name, parameters }, f }
}

///|
pub async fn[Output] Tool::call(
  tool : Tool[Output],
  args : Json,
) -> Result[Output] noraise {
  (tool.f)(args)
}

///|
struct AgentTool(Tool[(Json, String)])

///|
pub fn AgentTool::desc(self : AgentTool) -> ToolDesc {
  self.0.desc
}

///|
pub async fn AgentTool::call(
  self : AgentTool,
  args : Json,
) -> Result[(Json, String)] noraise {
  self.0.call(args)
}

///|
/// Convert a Tool[Output] to Tool[Json] by converting outputs to Json
pub fn[Output : ToJson + Show] Tool::to_agent_tool(
  self : Tool[Output],
) -> AgentTool {
  Tool::{
    desc: self.desc,
    f: args => match self.call(args) {
      Ok(output) => Ok((output.to_json(), output.to_string()))
      Error(error, output) => Error(error, output)
    },
  }
}
