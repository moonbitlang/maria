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

// x-ai/grok-4-fast

///|
// TODO(upstream): fmt allow blank line
pub(all) enum CommonModels {
  /// https://openrouter.ai/qwen/qwen3-coder-plus
  /// Starting at $1/M input tokens
  /// Starting at $5/M output tokens
  Qwen3CoderPlus
  /// https://openrouter.ai/qwen/qwen3-coder-flash
  /// Starting at $0.30/M input tokens
  /// Starting at $1.50/M output tokens
  Qwen3CoderFlash
  /// https://openrouter.ai/x-ai/grok-4-fast
  /// Starting at $0.20/M input tokens
  /// Starting at $0.50/M output tokens
  Grok4Fast
  /// https://openrouter.ai/x-ai/grok-code-fast-1
  /// $0.20/M input tokens
  /// $1.50/M output tokens
  GrokCodeFast1
  /// https://openrouter.ai/anthropic/claude-haiku-4.5
  /// $1/M input tokens
  /// $5/M output tokens
  ClaudeHaiku4_5
  /// https://openrouter.ai/anthropic/claude-sonnet-4.5
  /// Starting at $3/M input tokens
  /// Starting at $15/M output tokens
  ClaudeSonnet4_5
}
// qwen/qwen3-coder-flash

///|
impl Show for CommonModels with output(self : CommonModels, logger : &Logger) -> Unit {
  match self {
    Qwen3CoderPlus => logger.write_string("qwen/qwen3-coder-plus")
    Qwen3CoderFlash => logger.write_string("qwen/qwen3-coder-flash")
    Grok4Fast => logger.write_string("x-ai/grok-4-fast")
    GrokCodeFast1 => logger.write_string("x-ai/grok-code-fast-1")
    ClaudeHaiku4_5 => logger.write_string("anthropic/claude-haiku-4.5")
    ClaudeSonnet4_5 => logger.write_string("anthropic/claude-sonnet-4.5")
  }
}

///|
/// Default to qwen3-coder-plus model on OpenRouter
/// for testing
pub fn open_router_model(
  api_key~ : String,
  name? : CommonModels = GrokCodeFast1,
) -> Model {
  Model::new(
    api_key~,
    base_url="https://openrouter.ai/api/v1",
    name=name.to_string(),
    safe_zone_tokens=200_000,
  )
}
