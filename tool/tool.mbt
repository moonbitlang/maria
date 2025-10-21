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
  failed : Bool
} derive(ToJson)

///|
pub fn ok(output : String) -> Result {
  Result::{ output, failed: false }
}

///|
pub fn error(output : String) -> Result {
  Result::{ output, failed: true }
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
