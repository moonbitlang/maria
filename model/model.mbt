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
  // OAuth credentials for CodexOAuth provider
  access_token : String?
  account_id : String?
  refresh_token : String?
  id_token : String?
} derive(ToJson, Eq, Show)

///|
pub(all) enum Provider {
  OpenAI
  CodexOAuth
  Copilot
} derive(Eq, Show)

///|
pub(all) enum Type {
  SaaS(Provider)
} derive(Eq, Show)

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
  access_token? : String,
  account_id? : String,
  refresh_token? : String,
  id_token? : String,
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
    access_token,
    account_id,
    refresh_token,
    id_token,
  }
}

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
  /// https://openrouter.ai/anthropic/claude-opus-4.5
  /// $5/M input tokens
  /// $25/M output tokens
  ClaudeOpus4_5
  /// https://openrouter.ai/openai/gpt-5-codex
  /// $1.25/M input tokens
  /// $10/M output tokens
  Gpt5Codex
  /// https://openrouter.ai/openai/gpt-5
  /// $1.25/M input tokens
  /// $10/M output tokens
  Gpt5
  /// https://openrouter.ai/openai/gpt-5-mini
  /// $0.25/M input tokens
  /// $2/M output tokens
  Gpt5Mini
  /// https://openrouter.ai/openai/gpt-5-nano
  /// $0.05/M input tokens
  /// $0.40/M output tokens
  Gpt5Nano
  /// https://openrouter.ai/moonshotai/kimi-k2-0905
  /// $0.39/M input tokens
  /// $1.90/M output tokens
  KimiK2_0905
  /// https://openrouter.ai/z-ai/glm-4.6
  /// $0.40/M input tokens
  /// $1.75/M output tokens
  Glm4_6
  /// https://openrouter.ai/minimax/minimax-m2
  /// $0.15/M input tokens
  /// $0.45/M output tokens
  MinimaxM2
  /// https://openrouter.ai/deepseek/deepseek-v3.2
  /// $0.27/M input tokens
  /// $0.40/M output tokens
  DeepseekV3_2
}

///|
pub impl Show for CommonModels with output(
  self : CommonModels,
  logger : &Logger,
) -> Unit {
  match self {
    Qwen3CoderPlus => logger.write_string("qwen/qwen3-coder-plus")
    Qwen3CoderFlash => logger.write_string("qwen/qwen3-coder-flash")
    Grok4Fast => logger.write_string("x-ai/grok-4-fast")
    GrokCodeFast1 => logger.write_string("x-ai/grok-code-fast-1")
    ClaudeHaiku4_5 => logger.write_string("anthropic/claude-haiku-4.5")
    ClaudeSonnet4_5 => logger.write_string("anthropic/claude-sonnet-4.5")
    ClaudeOpus4_5 => logger.write_string("anthropic/claude-opus-4.5")
    Gpt5Codex => logger.write_string("openai/gpt-5-codex")
    Gpt5 => logger.write_string("openai/gpt-5")
    Gpt5Mini => logger.write_string("openai/gpt-5-mini")
    Gpt5Nano => logger.write_string("openai/gpt-5-nano")
    KimiK2_0905 => logger.write_string("moonshotai/kimi-k2-0905")
    Glm4_6 => logger.write_string("z-ai/glm-4.6")
    MinimaxM2 => logger.write_string("minimax/minimax-m2")
    DeepseekV3_2 => logger.write_string("deepseek/deepseek-v3.2")
  }
}

///|
fn CommonModels::safe_zone_tokens(self : CommonModels) -> Int {
  match self {
    Qwen3CoderPlus => 128_000
    Qwen3CoderFlash => 128_000
    Grok4Fast => 2_000_000
    GrokCodeFast1 => 256_000
    ClaudeHaiku4_5 => 200_000
    ClaudeSonnet4_5 =>
      // Although sonnet supports 1 M context, but providers tends to charge
      // at a higher rate for context > 200 K. So we keep the safe zone at 200 K
      200_000
    ClaudeOpus4_5 => 200_000
    Gpt5Codex => 400_000
    Gpt5 => 400_000
    Gpt5Mini => 400_000
    Gpt5Nano => 400_000
    KimiK2_0905 => 262_144
    Glm4_6 => 202_752
    MinimaxM2 => 204_800
    DeepseekV3_2 => 200_000
  }
}

///|
/// Default to qwen3-coder-plus model on OpenRouter
/// for testing
pub fn open_router_model(
  api_key~ : String,
  name? : CommonModels = Qwen3CoderPlus,
) -> Model {
  Model::new(
    api_key~,
    base_url="https://openrouter.ai/api/v1",
    name=name.to_string(),
    safe_zone_tokens=name.safe_zone_tokens(),
  )
}

///|
pub(all) enum CodexModels {
  Gpt5_2
}

///|
pub impl Show for CodexModels with output(self : CodexModels, logger : &Logger) -> Unit {
  match self {
    Gpt5_2 => logger.write_string("gpt-5.2")
  }
}

///|
fn CodexModels::safe_zone_tokens(self : CodexModels) -> Int {
  match self {
    Gpt5_2 => 400_000
  }
}

///|
pub fn codex_oauth_model(
  access_token~ : String,
  account_id~ : String,
  refresh_token~ : String,
  id_token? : String,
  name? : CodexModels = Gpt5_2,
) -> Model {
  Model::new(
    api_key="", // Not used for CodexOAuth
    base_url="https://chatgpt.com/backend-api",
    name=name.to_string(),
    model_name=name.to_string(),
    model_type=SaaS(CodexOAuth),
    safe_zone_tokens=name.safe_zone_tokens(),
    access_token~,
    account_id~,
    refresh_token~,
    id_token?,
  )
}

///|
pub(all) enum CopilotModels {
  // OpenAI models
  /// GPT-4.1 via GitHub Copilot
  Gpt4_1
  /// GPT-4o via GitHub Copilot
  Gpt4o
  /// GPT-5 via GitHub Copilot
  Gpt5
  /// GPT-5 mini via GitHub Copilot
  Gpt5Mini
  /// GPT-5-Codex via GitHub Copilot
  Gpt5Codex
  /// GPT-5.1 via GitHub Copilot
  Gpt5_1
  /// GPT-5.1 Codex via GitHub Copilot
  Gpt5_1Codex
  /// GPT-5.1 Codex Max via GitHub Copilot
  Gpt5_1CodexMax
  /// GPT-5.1 Codex Mini via GitHub Copilot
  Gpt5_1CodexMini
  /// GPT-5.2 via GitHub Copilot
  Gpt5_2
  /// o3 via GitHub Copilot
  O3
  /// o3-mini via GitHub Copilot
  O3Mini
  /// o4-mini via GitHub Copilot
  O4Mini
  // Anthropic models
  /// Claude 3.5 Sonnet via GitHub Copilot
  Claude3_5Sonnet
  /// Claude 3.7 Sonnet via GitHub Copilot
  Claude3_7Sonnet
  /// Claude 3.7 Sonnet Thought via GitHub Copilot
  Claude3_7SonnetThought
  /// Claude Haiku 4.5 via GitHub Copilot
  ClaudeHaiku4_5
  /// Claude Opus 4 via GitHub Copilot
  ClaudeOpus4
  /// Claude Opus 4.5 via GitHub Copilot
  ClaudeOpus4_5
  /// Claude Opus 41 via GitHub Copilot
  ClaudeOpus41
  /// Claude Sonnet 4 via GitHub Copilot
  ClaudeSonnet4
  /// Claude Sonnet 4.5 via GitHub Copilot
  ClaudeSonnet4_5
  // Google models
  /// Gemini 2.0 Flash via GitHub Copilot
  Gemini2_0Flash
  /// Gemini 2.5 Pro via GitHub Copilot
  Gemini2_5Pro
  /// Gemini 3 Flash Preview via GitHub Copilot
  Gemini3FlashPreview
  /// Gemini 3 Pro Preview via GitHub Copilot
  Gemini3ProPreview
  // xAI models
  /// Grok Code Fast 1 via GitHub Copilot
  GrokCodeFast1
}

///|
pub impl Show for CopilotModels with output(
  self : CopilotModels,
  logger : &Logger,
) -> Unit {
  match self {
    Gpt4_1 => logger.write_string("gpt-4.1")
    Gpt4o => logger.write_string("gpt-4o")
    Gpt5 => logger.write_string("gpt-5")
    Gpt5Mini => logger.write_string("gpt-5-mini")
    Gpt5Codex => logger.write_string("gpt-5-codex")
    Gpt5_1 => logger.write_string("gpt-5.1")
    Gpt5_1Codex => logger.write_string("gpt-5.1-codex")
    Gpt5_1CodexMax => logger.write_string("gpt-5.1-codex-max")
    Gpt5_1CodexMini => logger.write_string("gpt-5.1-codex-mini")
    Gpt5_2 => logger.write_string("gpt-5.2")
    O3 => logger.write_string("o3")
    O3Mini => logger.write_string("o3-mini")
    O4Mini => logger.write_string("o4-mini")
    Claude3_5Sonnet => logger.write_string("claude-3.5-sonnet")
    Claude3_7Sonnet => logger.write_string("claude-3.7-sonnet")
    Claude3_7SonnetThought => logger.write_string("claude-3.7-sonnet-thought")
    ClaudeHaiku4_5 => logger.write_string("claude-haiku-4.5")
    ClaudeOpus4 => logger.write_string("claude-opus-4")
    ClaudeOpus4_5 => logger.write_string("claude-opus-4.5")
    ClaudeOpus41 => logger.write_string("claude-opus-41")
    ClaudeSonnet4 => logger.write_string("claude-sonnet-4")
    ClaudeSonnet4_5 => logger.write_string("claude-sonnet-4.5")
    Gemini2_0Flash => logger.write_string("gemini-2.0-flash-001")
    Gemini2_5Pro => logger.write_string("gemini-2.5-pro")
    Gemini3FlashPreview => logger.write_string("gemini-3-flash-preview")
    Gemini3ProPreview => logger.write_string("gemini-3-pro-preview")
    GrokCodeFast1 => logger.write_string("grok-code-fast-1")
  }
}

///|
fn CopilotModels::safe_zone_tokens(self : CopilotModels) -> Int {
  match self {
    Gpt4_1 => 1_000_000
    Gpt4o => 128_000
    Gpt5 => 400_000
    Gpt5Mini => 400_000
    Gpt5Codex => 400_000
    Gpt5_1 => 400_000
    Gpt5_1Codex => 400_000
    Gpt5_1CodexMax => 400_000
    Gpt5_1CodexMini => 400_000
    Gpt5_2 => 400_000
    O3 => 200_000
    O3Mini => 200_000
    O4Mini => 200_000
    Claude3_5Sonnet => 200_000
    Claude3_7Sonnet => 200_000
    Claude3_7SonnetThought => 200_000
    ClaudeHaiku4_5 => 200_000
    ClaudeOpus4 => 200_000
    ClaudeOpus4_5 => 200_000
    ClaudeOpus41 => 200_000
    ClaudeSonnet4 => 200_000
    ClaudeSonnet4_5 => 200_000
    Gemini2_0Flash => 1_000_000
    Gemini2_5Pro => 1_000_000
    Gemini3FlashPreview => 1_000_000
    Gemini3ProPreview => 1_000_000
    GrokCodeFast1 => 256_000
  }
}

///|
pub fn copilot_model(
  copilot_token~ : String,
  github_token~ : String,
  name? : CopilotModels = Gpt4_1,
) -> Model {
  Model::new(
    api_key=copilot_token,
    base_url="https://api.githubcopilot.com",
    name=name.to_string(),
    model_name=name.to_string(),
    model_type=SaaS(Copilot),
    safe_zone_tokens=name.safe_zone_tokens(),
    refresh_token=github_token, // Store github_token as refresh_token for refreshing
  )
}
