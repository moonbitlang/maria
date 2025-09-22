///|
pub struct Tool[T] {
  description : String
  name : String
  parameters : Map[String, Json]
  priv f : async (Json, T) -> Result noraise
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
pub fn error(output : String, error? : Error = Failure(output)) -> Result {
  Result::{ output, error: Some(error) }
}

///|
pub fn[T] tool(
  description~ : String,
  name~ : String,
  parameters~ : Map[String, Json],
  f : async (Json, T) -> Result noraise,
) -> Tool[T] {
  Tool::{ description, name, parameters, f }
}

///|
pub async fn[T] Tool::call(
  tool : Tool[T],
  args : Json,
  state : T,
) -> Result noraise {
  (tool.f)(args, state)
}
