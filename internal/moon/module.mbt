///|
pub struct Module {
  priv path : String
  priv name : String
  priv source : String
  priv packages : Map[String, Package]
  coverage : Coverage
  priv mut core : Module?
  priv cakes : Map[String, Module]
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
  let moon_mod_text = @fs.read_file(moon_mod_path)
  let moon_mod_json = @json.parse(moon_mod_text)
  guard moon_mod_json is Object({ "name": String(name), .. } as moon_mod_json) else {
    raise Failure("Invalid moon.mod.json: expected object with 'name'.")
  }
  let source : String = if moon_mod_json is { "source": String(source), .. } {
    if @path.is_absolute(source) {
      source
    } else {
      @fs.resolve(@path.join(path, source))
    }
  } else {
    path
  }
  Module::{
    path,
    name,
    source,
    packages: {},
    coverage: { path, },
    core: None,
    cakes: {},
  }
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
  self.source
}

///|
async fn Module::load_pkg(
  self : Module,
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

  // Skip if this is the root module path.
  if dir != self.path {
    // If there is a moon.mod.json here, load it as a module.
    let moon_mod_path = @path.join(dir, "moon.mod.json")
    if @fs.exists(moon_mod_path) &&
      @fs.kind(moon_mod_path) is @fs.FileKind::Regular {
      return
    }
  }

  // If there is a moon.pkg.json here, load it as a package.
  let moon_pkg_path = @path.join(dir, "moon.pkg.json")
  if !@fs.exists_as_file(moon_pkg_path) {
    let entries = @fs.list_directory(dir)
    for entry in entries {
      if entry.kind is Directory {
        if entry.name is ".moonagent" {
          continue
        }
        self.load_pkg(entry.path, visit~)
      }
    }
    return
  }
  let pkg_name = {
    let mod_src = @fs.resolve(self.source())
    let rel = @path.relative(mod_src, dir)
    if rel is "." {
      self.name()
    } else {
      "\{self.name()}/\{rel}"
    }
  }
  let pkg = Package::new(name=pkg_name, path=dir.to_string())
  self.add_package(pkg)
  let entries = @fs.list_directory(dir)
  for entry in entries {
    if entry.kind is Directory {
      if entry.name is ".moonagent" {
        continue
      }
      self.load_pkg(entry.path, visit~)
    } else if entry.kind is Regular {
      if entry.name.has_suffix(".mbt") || entry.name.has_suffix(".mbt.md") {
        pkg.add_file(entry.path)
      }
    }
  }
}

///|
async fn Module::scan(self : Module) -> Unit {
  let visit : Set[String] = Set::new()
  self.load_pkg(self.source, visit~)
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
  let parts = @path.split(name).collect()
  guard parts is [author, module_, ..] else { return None }
  let mod_name = @path.join(author, module_)
  if self.cakes.get(mod_name) is Some(cake_mod) {
    return cake_mod.package_(name)
  }
  let cakes_path = @path.join(self.path, ".mooncakes")
  if !@fs.exists(cakes_path) {
    self.install()
  }
  let cakes_path = @fs.resolve(cakes_path)
  let mod_path = @path.join(cakes_path, mod_name)
  if !@fs.exists(mod_path) {
    return None
  }
  let cake_mod = Module::new(mod_path)
  cake_mod.scan()
  self.cakes[cake_mod.name()] = cake_mod
  cake_mod.package_(name)
}

///|
pub fn Module::packages(self : Module) -> Iter[PackageView] {
  self.packages
  .values()
  .map(pkg => PackageView::{ module_: self, name: pkg.name })
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
  let packages = self.packages.values().collect()
  let mut diags = Iter::empty()
  for i in 0..<packages.length() {
    let package_ = packages[i]
    diags = diags.concat(package_.diagnostics())
  }
  diags
}

///|
fn Module::package_(self : Module, name : String) -> PackageView? {
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
