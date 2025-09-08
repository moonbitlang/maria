///|
pub struct Model {
  name : String
  api_key : String
  base_url : String
  context_window : Int
}

///|
/// Creates a new Model instance with the specified configuration parameters.
///
/// Parameters:
///
/// * `api_key` : The API key for authenticating with the language model
///   service.
/// * `base_url` : The base URL of the language model API endpoint.
/// * `name` : The name or identifier of the language model.
/// * `context_window` : The maximum number of tokens that can be processed in a
///   single request.
///
/// Returns a new `Model` instance configured with the provided parameters.
pub fn new(
  api_key~ : String,
  base_url~ : String,
  name~ : String,
  context_window~ : Int,
) -> Model {
  Model::{ api_key, base_url, name, context_window }
}
