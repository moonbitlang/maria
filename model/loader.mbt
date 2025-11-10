///|
struct Loader {
  logger : @pino.Logger
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
pub async fn Loader::new(
  home~ : StringView,
  cwd~ : StringView,
  logger~ : @pino.Logger,
) -> Loader {
  let loader = Loader::{ home, cwd, models: [], logger }
  loader.load()
  loader
}

///|
async fn Model::load_from_path(path : StringView) -> Array[Model] {
  let text = @fsx.read_file(path)
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
  if @fsx.exists(project) {
    self.models.append(Model::load_from_path(project))
  }
  let user = self.home
    |> @path.join(".moonagent")
    |> @path.join("models")
    |> @path.join("models.json")
  if @fsx.exists(user) {
    self.models.append(Model::load_from_path(user))
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
pub async fn Loader::get_model(
  self : Loader,
  name? : String,
  api_key? : String,
  base_url? : String,
) -> Model? {
  let name : String? = match name {
    Some(name) => Some(name)
    None =>
      if (try? @os.getenv("MODEL_NAME")) is Ok(Some(name)) {
        Some(name)
      } else {
        None
      }
  }
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
  self.logger.info("ModelLoaded", {
    "name": name.to_json(),
    "model": {
      let json = model.to_json()
      if json is Object(obj) {
        obj["api_key"] = "****"
        Json::object(obj)
      } else {
        json
      }
    },
  })
  if model is Some(model) {
    let model = if api_key is Some(api_key) {
      { ..model, api_key, }
    } else if (try? @os.getenv("OPENAI_API_KEY")) is Ok(Some(api_key)) {
      { ..model, api_key, }
    } else if (try? @os.getenv("OPENROUTER_API_KEY")) is Ok(Some(api_key)) {
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
