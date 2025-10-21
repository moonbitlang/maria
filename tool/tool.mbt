///|
pub struct ToolDesc {
  description : String
  name : String
  parameters : Map[String, Json]
}

///|
pub struct Tool[T] {
  desc : ToolDesc
  priv f : ToolFn[T]
}

///|
pub(all) struct ToolFn[T](async (Json, T) -> Result noraise)

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
pub fn error(output : String, error? : Error = Failure(output)) -> Result {
  Result::{ output, error: Some(error) }
}

///|
pub fn[T] tool(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
  f : ToolFn[T],
) -> Tool[T] {
  Tool::{ desc: { description, name, parameters }, f }
}

///|
pub async fn[T] Tool::call(
  tool : Tool[T],
  args : Json,
  state : T,
) -> Result noraise {
  (tool.f)(args, state)
}
