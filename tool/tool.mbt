///|
pub struct Tool {
  description : String
  name : String
  parameters : Map[String, Json]
  priv f : async (Json, Context) -> Result noraise
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
  model : @model.Model
  cwd : String
}

///|
pub fn context(model~ : @model.Model, cwd~ : String) -> Context {
  Context::{ model, cwd }
}

///|
pub async fn Tool::call(
  self : Tool,
  args : Json,
  context : Context,
) -> Result noraise {
  (self.f)(args, context)
}
