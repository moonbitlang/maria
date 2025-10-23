///|
pub struct ToolDesc {
  description : String
  name : String
  parameters : Json
}

///|
pub struct Tool[T] {
  desc : ToolDesc
  priv f : ToolFn[T]
  render : async (Result) -> String noraise
}

///|
pub(all) struct ToolFn[T](async (Json, T) -> Result noraise)

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
pub fn[T] tool(
  description~ : String,
  name~ : String,
  parameters~ : Json,
  f : ToolFn[T],
  render~ : async (Result) -> String noraise,
) -> Tool[T] {
  Tool::{ desc: { description, name, parameters }, f, render }
}

///|
pub async fn[T] Tool::call(
  tool : Tool[T],
  args : Json,
  state : T,
) -> Result noraise {
  (tool.f)(args, state)
}
