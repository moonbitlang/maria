///|
struct Loader {
  home : StringView
  cwd : StringView
  models : Array[Model]
}

///|
/// Create a model loader scoped to the given home directory and
/// current working directory.
///
/// Parameters:
///
/// - home: Absolute path to the user's home directory.
/// - cwd: Absolute path to the current project directory.
///
/// Returns a Loader instance with an empty model cache that can be
/// populated by calling `load`.
///
/// Populate the loader's in-memory model cache by reading project and
/// user model configuration files.
///
/// The loader looks for `.moonagent/models/models.json` inside the
/// current working directory first, then the user's home directory. If
/// either file exists, the models defined there are appended to the
/// loader's cache.
pub async fn Loader::new(home? : StringView, cwd? : StringView) -> Loader {
  let home = match home {
    Some(home) => home
    None => @os.home()
  }
  let cwd = match cwd {
    Some(cwd) => cwd
    None => @os.cwd()
  }
  let loader = Loader::{ home, cwd, models: [] }
  loader.load()
  loader
}

///|
async fn Loader::load(self : Loader) -> Unit {
  self.models.clear()
  async fn load_from_path(path : StringView) -> Array[Model] {
    let text = @fsx.read_file(path)
    let json = @json.parse(text)
    @json.from_json(json)
  }

  let project = self.cwd
    |> @pathx.join(".moonagent")
    |> @pathx.join("models")
    |> @pathx.join("models.json")
  if @fsx.exists(project) {
    self.models.append(load_from_path(project))
  }
  let user = self.home
    |> @pathx.join(".moonagent")
    |> @pathx.join("models")
    |> @pathx.join("models.json")
  if @fsx.exists(user) {
    self.models.append(load_from_path(user))
  }
}

///|
/// Retrieve a model from the loader's cache, optionally overriding
/// selected fields.
///
/// Parameters:
/// - name: Model name to look up. When omitted, the first cached model
///   is returned (if any).
/// - api_key: Optional API key override for the returned model.
/// - base_url: Optional base URL override for the returned model.
///
/// Returns the matching model with overrides applied, or `None` when no
/// model is available.
pub async fn Loader::get_model(self : Loader, name? : String) -> Model? {
  self.load()
  if name is Some(model_name) && model_name.has_prefix("codex/") {
    return self.load_codex_model(model_name, allow_auto_login=true)
  }
  let model = if name is Some(name) {
    for model in self.models {
      if model.name == name {
        println("[INFO] Loaded model '\{name}' from configuration")
        break Some(model)
      }
    } else {
      None
    }
  } else {
    self.models.get(0)
  }
  if model is Some(model) {
    return Some(model)
  }
  if name is Some(model_name) {
    return self.load_openrouter_model(Some(model_name))
  }
  println("[INFO] No model specified, auto-detecting...")
  if self.load_openrouter_model(None) is Some(model) {
    return Some(model)
  }
  if self.load_codex_model("codex/gpt-5.2", allow_auto_login=false)
    is Some(model) {
    return Some(model)
  }
  println(
    "[ERROR] No API key found. Set OPENROUTER_API_KEY/OPENAI_API_KEY environment variable or use a codex/ model to authenticate via OAuth.",
  )
  None
}

///|
fn Loader::load_openrouter_model(self : Loader, name : String?) -> Model? raise {
  let _ = self
  let api_key = if @os.getenv("OPENROUTER_API_KEY") is Some(api_key) {
    Some(api_key)
  } else if @os.getenv("OPENAI_API_KEY") is Some(api_key) {
    Some(api_key)
  } else {
    None
  }
  guard api_key is Some(api_key) else { return None }
  let base_url = "https://openrouter.ai/api/v1"
  let (model_name, safe_zone_tokens, supports_anthropic_prompt_caching) = match
    name {
    Some("qwen/qwen3-coder-plus") => ("qwen/qwen3-coder-plus", 128_000, false)
    Some("qwen/qwen3-coder-flash") => ("qwen/qwen3-coder-flash", 128_000, false)
    Some("x-ai/grok-4-fast") => ("x-ai/grok-4-fast", 2_000_000, false)
    Some("x-ai/grok-code-fast-1") => ("x-ai/grok-code-fast-1", 256_000, false)
    Some("anthropic/claude-haiku-4.5") =>
      ("anthropic/claude-haiku-4.5", 200_000, true)
    Some("anthropic/claude-sonnet-4.5") =>
      ("anthropic/claude-sonnet-4.5", 200_000, true)
    Some("anthropic/claude-opus-4.5") =>
      ("anthropic/claude-opus-4.5", 200_000, true)
    Some("openai/gpt-5-codex") => ("openai/gpt-5-codex", 400_000, false)
    Some("openai/gpt-5") => ("openai/gpt-5", 400_000, false)
    Some("openai/gpt-5-mini") => ("openai/gpt-5-mini", 400_000, false)
    Some("openai/gpt-5-nano") => ("openai/gpt-5-nano", 400_000, false)
    Some("moonshotai/kimi-k2-0905") =>
      ("moonshotai/kimi-k2-0905", 262_144, false)
    Some("z-ai/glm-4.6") => ("z-ai/glm-4.6", 202_752, false)
    Some("minimax/minimax-m2") => ("minimax/minimax-m2", 204_800, false)
    Some("deepseek/deepseek-v3.2") => ("deepseek/deepseek-v3.2", 200_000, false)
    None => ("anthropic/claude-sonnet-4.5", 200_000, true)
    Some(other) => (other, 128_000, false)
  }
  println("[INFO] Using OpenRouter model '\{model_name}'")
  let model = Model::new(
    api_key~,
    base_url~,
    name=model_name,
    safe_zone_tokens~,
    supports_anthropic_prompt_caching~,
  )
  Some(model)
}

///|
async fn Loader::load_codex_model(
  self : Loader,
  name : String,
  allow_auto_login~ : Bool,
) -> Model? {
  let credentials_path = @pathx.join(self.home, ".codex/auth.json")
  let credentials = if @fsx.exists(credentials_path) {
    @oauth.load_credentials() catch {
      err => {
        println("[WARN] Failed to load Codex OAuth credentials: \{err}")
        if not(allow_auto_login) {
          return None
        }
        println("[INFO] Starting OAuth login flow...")
        @oauth.start_oauth_flow() catch {
          login_err => {
            println("[ERROR] OAuth login failed: \{login_err}")
            return None
          }
        }
      }
    }
  } else {
    if not(allow_auto_login) {
      return None
    }
    println("[INFO] Codex OAuth credentials not found, starting login...")
    @oauth.start_oauth_flow() catch {
      err => {
        println("[ERROR] OAuth login failed: \{err}")
        return None
      }
    }
  }
  let codex_model = match name {
    "codex/gpt-5.2" => Gpt5_2
    _ => {
      println("[WARN] Unknown Codex model '\{name}', using gpt-5.2")
      Gpt5_2
    }
  }
  println("[INFO] Using Codex OAuth model '\{codex_model}'")
  let model = codex_oauth_model(
    access_token=credentials.accessToken,
    account_id=credentials.accountId,
    refresh_token=credentials.refreshToken,
    id_token=credentials.idToken,
    name=codex_model,
  )
  Some(model)
}

///|
/// Returns a read-only view of all models currently cached in the loader.
///
/// Parameters:
///
/// * `self` : The loader instance to get models from.
///
/// Returns an `ArrayView[Model]` containing all cached models.
pub async fn Loader::models(self : Loader) -> ArrayView[Model] {
  self.load()
  self.models
}

///|
pub async fn load(
  home? : StringView,
  cwd? : StringView,
  name? : String,
) -> Model? {
  Loader::new(home?, cwd?).get_model(name?)
}
