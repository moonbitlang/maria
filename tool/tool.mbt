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
  render : async (Result) -> String noraise
}

///|
typealias async (Json, T) -> Result noraise as ToolFn[T]

///|
pub struct Result {
  output : Json
  error : Error?
} derive(ToJson)

///|
pub fn ok(output : Json) -> Result {
  Result::{ output, error: None }
}

///|
priv suberror Failure Json derive(ToJson)

///|
pub fn error(output : Json, error? : Error = Failure(output)) -> Result {
  Result::{ output, error: Some(error) }
}

///|
pub fn[T] tool(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
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
