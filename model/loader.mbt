///|
priv struct Loader {
  home : StringView
  cwd : StringView
  models : Array[Model]
}

///|
/// Create a model loader scoped to the given home directory and
/// current working directory.
///
/// Parameters:
/// - home: Absolute path to the user's home directory.
/// - cwd: Absolute path to the current project directory.
///
/// Returns a Loader instance with an empty model cache that can be
/// populated by calling `load`.
fn Loader::new(home~ : StringView, cwd~ : StringView) -> Loader {
  Loader::{ home, cwd, models: [] }
}

///|
async fn Model::load_from_path(path : StringView) -> Array[Model] {
  let text = @fs.read_file(path)
  let json = @json.parse(text)
  @json.from_json(json)
}

///|
/// Populate the loader's in-memory model cache by reading project and
/// user model configuration files.
///
/// The loader looks for `.moonagent/models/models.json` inside the
/// current working directory first, then the user's home directory. If
/// either file exists, the models defined there are appended to the
/// loader's cache.
async fn Loader::load(self : Loader) -> Unit {
  let project = self.cwd
    |> @path.join(".moonagent")
    |> @path.join("models")
    |> @path.join("models.json")
  if @fs.exists(project) {
    self.models.append(Model::load_from_path(project))
  }
  let user = self.home
    |> @path.join(".moonagent")
    |> @path.join("models")
    |> @path.join("models.json")
  if @fs.exists(user) {
    self.models.append(Model::load_from_path(user))
  }
}

///|
pub async fn load_model(
  home~ : String,
  cwd~ : String,
  model? : String,
) -> Model? {
  let model_loader = Loader::new(home~, cwd~)
  model_loader.load()
  let api_key : String? = if @os.getenv("OPENAI_API_KEY") is (Some(_) as key) {
    key
  } else {
    @os.getenv("OPENROUTER_API_KEY")
  }
  let name : String? = if model is (Some(_) as model) {
    model
  } else {
    @os.getenv("MODEL_NAME")
  }
  return model_loader.get_model(name?, api_key?)
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
fn Loader::get_model(
  self : Loader,
  name? : String,
  api_key? : String,
  base_url? : String,
) -> Model? {
  let model = if name is Some(name) {
    for model in self.models {
      if model.name == name {
        break Some(model)
      }
    } else {
      None
    }
  } else {
    self.models.get(0)
  }
  if model is Some(model) {
    let model = if api_key is Some(api_key) {
      { ..model, api_key, }
    } else {
      model
    }
    let model = if base_url is Some(base_url) {
      { ..model, base_url, }
    } else {
      model
    }
    Some(model)
  } else {
    None
  }
}
