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
  // let load_from_path = async fn (path) => {
  //   let text = @fsx.read_file(path)
  //   let json = @json.parse(text)
  //   (@json.from_json(json) : Array[Model])
  // }
  // TODO: arrow function does not work yet
  async fn load_from_path(path : StringView) -> Array[Model] {
    let text = @fsx.read_file(path)
    let json = @json.parse(text)
    @json.from_json(json)
  }

  let project = loader.cwd
    |> @path.join(".moonagent")
    |> @path.join("models")
    |> @path.join("models.json")
  if @fsx.exists(project) {
    loader.models.append(load_from_path(project))
  }
  let user = loader.home
    |> @path.join(".moonagent")
    |> @path.join("models")
    |> @path.join("models.json")
  if @fsx.exists(user) {
    loader.models.append(load_from_path(user))
  }
  loader
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
  println("[WARN] Unable to find configured model")
  let api_key = if @os.getenv("OPENROUTER_API_KEY") is Some(api_key) {
    Some(api_key)
  } else if @os.getenv("OPENROUTER_API_KEY") is Some(api_key) {
    Some(api_key)
  } else {
    None
  }
  guard api_key is Some(api_key) else {
    println(
      "[ERROR] OPENROUTER_API_KEY environment variable not set, unable to load default model",
    )
    return None
  }
  println(
    "[INFO] Detected OPENROUTER_API_KEY environment variable, falling back to Anthropic Claude Sonnet 4.5 (OpenRouter)",
  )
  let base_url = "https://openrouter.ai/api/v1"
  let name = "anthropic/claude-sonnet-4.5"
  let model = Model::new(
    api_key~,
    base_url~,
    name~,
    safe_zone_tokens=128000,
    supports_anthropic_prompt_caching=true,
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
pub fn Loader::models(self : Loader) -> ArrayView[Model] {
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
