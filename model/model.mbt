///|
pub struct Model {
  name : String
  description : String?
  model_name : String
  model_type : Type
  api_key : String
  base_url : String
  safe_zone_tokens : Int
  supports_anthropic_prompt_caching : Bool
} derive(ToJson)

///|
pub(all) enum Provider {
  OpenAI
}

///|
pub(all) enum Type {
  SaaS(Provider)
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
  safe_zone_tokens~ : Int,
  model_name? : String = name,
  model_type? : Type = SaaS(OpenAI),
  description? : String,
  supports_anthropic_prompt_caching? : Bool = false,
) -> Model {
  Model::{
    api_key,
    base_url,
    name,
    description,
    safe_zone_tokens,
    model_name,
    model_type,
    supports_anthropic_prompt_caching,
  }
}
