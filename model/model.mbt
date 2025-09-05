///|
pub struct Model {
  name : String
  api_key : String
  base_url : String
  context_window : Int
}

///|
pub fn new(
  api_key~ : String,
  base_url~ : String,
  name~ : String,
  context_window~ : Int,
) -> Model {
  Model::{ api_key, base_url, name, context_window }
}
