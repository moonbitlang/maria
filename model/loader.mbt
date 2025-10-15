///|
struct Loader {
  home : StringView
  cwd : StringView
  models : Array[Model]
}

///|
pub fn loader(home~ : StringView, cwd~ : StringView) -> Loader {
  Loader::{ home, cwd, models: [] }
}

///|
pub suberror NotConfigured

///|
async fn Model::load_from_path(path : StringView) -> Array[Model] {
  let text = @fs.read_file(path)
  let json = @json.parse(text)
  @json.from_json(json)
}

///|
pub async fn Loader::load(self : Loader) -> Unit {
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
  if self.models.is_empty() {
    raise NotConfigured
  }
}

///|
pub fn Loader::get_model(
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
