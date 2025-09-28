///|
struct Project {
  module_ : Module
  mut core : Module?
  cakes : Map[String, Module]
}

///|
pub async fn Project::new(path : String) -> Project {
  let module_ = Module::load(path)
  Project::{ module_, core: None, cakes: {} }
}

///|
pub fn Project::name(self : Project) -> String {
  self.module_.name()
}

///|
async fn Project::core(self : Project) -> Module {
  if self.core is Some(core) {
    return core
  }
  let core = Module::load(home() |> @path.join("lib") |> @path.join("core"))
  self.core = Some(core)
  core
}

///|
pub async fn Project::package_(self : Project, name : String) -> PackageView? {
  if name.has_prefix(self.name()) {
    return self.module_.package_(name)
  }
  if name.has_prefix("moonbitlang/core") {
    let core = self.core()
    return core.package_(name)
  }
  let parts = @path.split(name).collect()
  guard parts is [author, module_, ..] else { return None }
  let module_name = @path.join(author, module_)
  match self.cakes.get(module_name) {
    Some(cake) => return cake.package_(name)
    None => {
      let cake = self.module_.path
        |> @path.join(".mooncakes")
        |> @path.join(module_name)
        |> Module::load
      self.cakes[module_name] = cake
      return cake.package_(name)
    }
  }
  None
}

///|
fn home() -> String raise {
  if @os.getenv("MOON_HOME") is Some(moon_home) {
    return moon_home
  } else {
    return @os.home() |> @path.join(".moon")
  }
}
