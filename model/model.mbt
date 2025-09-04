///|
pub struct Model {
  name : String
  api_key : String
  base_url : String
}

///|
pub fn Model::new(
  api_key~ : String,
  base_url~ : String,
  name~ : String,
) -> Model {
  Model::{ api_key, base_url, name }
}
