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
/// Create a new model configuration describing how to reach a provider
/// backed language model.
///
/// Parameters:
/// - api_key: API key used when issuing requests to the model service.
/// - base_url: Base URL of the provider endpoint.
/// - name: Identifier for this configuration, used to select models.
/// - safe_zone_tokens: Token buffer reserved for internal bookkeeping.
/// - model_name: Optional provider specific model identifier.
/// - model_type: Optional provider and deployment metadata.
/// - description: Optional human readable description.
/// - supports_anthropic_prompt_caching: Enable Anthropic prompt caching
///   support when true.
///
/// Returns a Model value ready to be passed to higher level APIs.
#as_free_fn
pub fn Model::new(
  api_key~ : String,
  base_url~ : String,
  name~ : String,
  safe_zone_tokens~ : Int,
  model_name? : String = name,
  model_type? : Type = SaaS(OpenAI),
  description? : String,
  supports_anthropic_prompt_caching? : Bool = false,
) -> Model {
  {
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

///|
/// Deafult to qwen3-coder-plus model on OpenRouter
/// for testing
pub fn open_router_model(  
  api_key~ : String,
  name~ : String = "qwen/qwen3-coder-plus",
) -> Model {
  Model::new(
    api_key~,
    base_url = "https://openrouter.ai/api/v1",
    name~,
    safe_zone_tokens = 200_000,
  )
}  