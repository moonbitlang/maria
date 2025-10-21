///|
pub struct Module {
  path : String
  name : String
  priv source : String?
  priv packages : Map[String, Package]
  coverage : Coverage
  modules : Array[Module]
  priv mut core : Module?
  cakes : Map[String, Module]
}

///|
impl @json.FromJson for Module with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Module raise @json.JsonDecodeError {
  guard json is { "name": name, .. } else {
    raise @json.JsonDecodeError((json_path, "Expected object with 'name'."))
  }
  let name : String = @json.from_json(name, path=json_path.add_key("name"))
  let source : String? = if json is { "source": source, .. } {
    Some(@json.from_json(source, path=json_path.add_key("source")))
  } else {
    None
  }
  Module::{
    path: "",
    name,
    source,
    packages: {},
    coverage: { path: "" },
    modules: [],
    core: None,
    cakes: {},
  }
}

///|
async fn Module::core(self : Module) -> Module {
  if self.core is Some(core) {
    core
  } else {
    let core = Module::new(home() |> @path.join("lib") |> @path.join("core"))
    core.scan()
    self.core = Some(core)
    core
  }
}

///|
async fn Module::new(path : String) -> Module {
  let path = @fs.resolve(path)
  let moon_mod_path = @path.join(path, "moon.mod.json")
  let mod : Module = moon_mod_path
    |> @fs.read_file
    |> @json.parse
    |> @json.from_json
  { ..mod, path, coverage: { path, } }
}

///|
pub async fn Module::load(path : String) -> Module {
  let mod = Module::new(path)
  mod.scan()
  mod
}

///|
pub fn Module::name(self : Module) -> String {
  self.name
}

///|
pub fn Module::source(self : Module) -> String {
  match self.source {
    Some(source) => source
    None => self.path
  }
}

///|
async fn Module::load_mod(
  self : Module,
  mod : Module,
  dir : String,
  visit~ : Set[String],
) -> Unit {
  if !@fs.exists(dir) {
    return
  }
  let dir = @fs.resolve(dir)
  let moon_mod_path = @path.join(dir, "moon.mod.json")
  if @fs.exists(moon_mod_path) &&
    @fs.kind(moon_mod_path) is @fs.FileKind::Regular {
    let mod = Module::new(dir)
    self.modules.push(mod)
    let mod_src = @path.join(dir, mod.source())
    self.load_pkg(mod, mod_src, visit~)
  } else {
    self.load_pkg(mod, dir, visit~)
  }
}

///|
async fn Module::load_pkg(
  self : Module,
  mod : Module,
  dir : String,
  visit~ : Set[String],
) -> Unit {
  if !@fs.exists(dir) {
    return
  }
  let dir = @fs.resolve(dir)
  if visit.contains(dir) {
    return
  }
  visit.add(dir)
  let moon_pkg_path = @path.join(dir, "moon.pkg.json")
  if !@fs.exists_as_file(moon_pkg_path) {
    let entries = @fs.list_directory(dir)
    for entry in entries {
      if entry.kind is Directory {
        self.load_pkg(mod, entry.path, visit~)
      }
    }
    return
  }
  let pkg_name = {
    let rel = @path.relative(@path.join(self.path, mod.source()), dir)
    if rel is "." {
      mod.name()
    } else {
      "\{mod.name()}/\{rel}"
    }
  }
  let pkg = Package::new(name=pkg_name, path=dir.to_string())
  mod.add_package(pkg)
  let entries = @fs.list_directory(dir)
  for entry in entries {
    if entry.kind is Directory {
      self.load_mod(mod, entry.path, visit~)
    } else if entry.kind is Regular {
      if entry.name.has_suffix(".mbt") || entry.name.has_suffix(".mbt.md") {
        pkg.add_file(entry.path)
      }
    }
  }
}

///|
async fn Module::scan(self : Module) -> Unit {
  let src = @path.join(self.path, self.source())
  self.load_pkg(self, src, visit=Set::new())
}

///|
fn Module::add_package(self : Module, pkg : Package) -> Unit {
  self.packages[pkg.name] = pkg
}

///|
pub async fn Module::find_package(self : Module, name : String) -> PackageView? {
  if name.has_prefix("moonbitlang/core") {
    return self.core().package_(name)
  }
  if self.package_(name) is Some(package_) {
    return Some(package_)
  }
  for module_ in self.modules {
    if name.has_prefix(module_.name()) {
      return module_.package_(name)
    }
  }
  let parts = @path.split(name).collect()
  guard parts is [author, module_, ..] else { return None }
  let mod_name = @path.join(author, module_)
  match self.cakes.get(mod_name) {
    Some(cake) => return cake.package_(name)
    None => {
      let cake_path = self.path
        |> @path.join(".mooncakes")
        |> @path.join(mod_name)
      if !@fs.exists(cake_path) {
        return None
      }
      let cake = Module::load(cake_path)
      self.cakes[mod_name] = cake
      return cake.package_(name)
    }
  }
}

///|
pub async fn Module::find_module(self : Module, name : String) -> Module? {
  if name == self.name {
    return Some(self)
  }
  for module_ in self.modules {
    if module_.name == name {
      break Some(module_)
    }
  } else {
    None
  }
}

///|
pub fn Module::packages(self : Module) -> Iter[Package] {
  self.packages.values()
}

///|
pub fn Module::modules(self : Module) -> Iter[Module] {
  Iter::singleton(self).concat(self.modules.iter())
}

///|
pub fn Module::files(self : Module) -> Iter[File] {
  let packages = self.packages().collect()
  let mut files = Iter::empty()
  for i in 0..<packages.length() {
    let pkg = packages[i]
    files = files.concat(pkg.files())
  }
  files
}

///|
pub async fn Module::locate_package(self : Module, file : String) -> Package {
  let dir = @path.dirname(file)
  let src = self.source()
  let pkg_name = match @path.relative(src, dir) {
    "" | "." => self.name()
    rel => "\{self.name()}/\{rel}"
  }
  match self.packages.get(pkg_name) {
    Some(pkg) => pkg
    None => {
      let pkg = Package::new(name=pkg_name, path=dir.to_string())
      self.packages[pkg_name] = pkg
      pkg
    }
  }
}

///|
pub async fn Module::check(
  self : Module,
  patch_file? : StringView,
  target_dir? : StringView,
) -> Unit {
  self.clear_diagnostics()
  let diagnostics = check(patch_file?, target_dir?, cwd=self.path)
  for d in diagnostics {
    let pkg = self.locate_package(d.loc.path)
    pkg.add_diagnostic(d)
  }
}

///|
fn Module::clear_diagnostics(self : Module) -> Unit {
  for _, pkg in self.packages {
    pkg.clear_diagnostics()
  }
}

///|
pub async fn Module::diagnostics(self : Module) -> Iter[Diagnostic] {
  let pkgs = self.packages.values().collect()
  let mut diags = Iter::empty()
  for i in 0..<pkgs.length() {
    let pkg = pkgs[i]
    diags = diags.concat(pkg.diagnostics())
  }
  diags
}

///|
pub fn Module::package_(self : Module, name : String) -> PackageView? {
  match self.packages.get(name) {
    None => None
    Some(_) => Some(PackageView::{ module_: self, name })
  }
}

///|
async fn Module::info(self : Module, package_~ : String) -> Unit {
  info(package_~, cwd=self.path)
}

///|
pub async fn Module::install(self : Module) -> Unit {
  install(cwd=self.path)
}
