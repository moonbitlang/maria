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
    let home_path = @path.Path::parse(home(), kind=Directory)
    let path_builder = @path.PathBuilder::from_path(home_path)
    path_builder.add_directory("lib")
    path_builder.add_directory("core")
    let core = Module::new(path_builder.to_string(kind=File))
    core.scan()
    self.core = Some(core)
    core
  }
}

///|
async fn Module::new(path : String) -> Module {
  let path = @fs.resolve(path)
  let mod_dir_path = @path.Path::parse(path, kind=Directory)
  let path_builder = @path.PathBuilder::from_path(mod_dir_path)
  path_builder.set_file(base="moon.mod", extension="json")
  let moon_mod_path = path_builder.to_string()
  let moon_mod_text = @fs.read_file(moon_mod_path)
  let moon_mod_json = @json.parse(moon_mod_text)
  guard moon_mod_json is Object({ "name": String(name), .. } as moon_mod_json) else {
    raise Failure("Invalid moon.mod.json: expected object with 'name'.")
  }
  let source : String = if moon_mod_json is { "source": String(source), .. } {
    let source_path = @path.Path::parse(source + "/")
    if source_path.is_absolute() {
      source
    } else {
      let path_builder = @path.PathBuilder::from_path(mod_dir_path)
      path_builder.set_basename(source)
      @fs.resolve(path_builder.to_string())
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
    let dir_path = @path.Path::parse(dir, kind=Directory)
    let path_builder = @path.PathBuilder::from_path(dir_path)
    path_builder.set_file(base="moon.mod", extension="json")
    let moon_mod_path = path_builder.to_string()
    if @fs.exists(moon_mod_path) &&
      @fs.kind(moon_mod_path) is @fs.FileKind::Regular {
      return
    }
  }

  // If there is a moon.pkg.json here, load it as a package.
  let dir_path = @path.Path::parse(dir, kind=Directory)
  let path_builder = @path.PathBuilder::from_path(dir_path)
  path_builder.set_file(base="moon.pkg", extension="json")
  let moon_pkg_path = path_builder.to_string()
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
    let mod_path = @path.Path::parse(mod_src, kind=Directory)
    let dir_path = @path.Path::parse(dir, kind=Directory)
    // TODO: refactor extract calculate the pkg name logic 
    let pkg = loop (mod_path.directory()[:], dir_path.directory()[:]) {
      ([x, .. xs], [y, .. ys]) if x == y => continue (xs, ys)
      (_, ys) => break ys
    }
    let pkg_name = if pkg.length() == 0 {
      self.name()
    } else {
      self.name() + "/" + pkg.join("/")
    }
    pkg_name
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
  let name_path = @path.Path::parse(name)
  let parts = name_path.directory()[:]
  guard parts is [author, module_, ..] else { return None }
  // mod_name isn't the path but the identifier "author/module"
  let mod_name = author + "/" + module_
  if self.cakes.get(mod_name) is Some(cake_mod) {
    return cake_mod.package_(name)
  }
  let self_path = @path.Path::parse(self.path, kind=Directory)
  let path_builder = @path.PathBuilder::from_path(self_path)
  path_builder.add_directory(".mooncakes")
  let cakes_path = path_builder.to_string()
  if !@fs.exists(cakes_path) {
    self.install()
  }
  path_builder.add_directory(author)
  path_builder.add_directory(module_)
  let mod_path = path_builder.to_string()
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
  let path = @path.Path::parse(file)
  let dir = path.prefix() + path.directory()[:].join("/")
  let src = self.source()
  let src_path = @path.Path::parse(src)
  let dir_path = @path.Path::parse(dir)
  // don't abuse path operations to handle MoonBit package names and module sources
  let pkg = loop (src_path.directory()[:], dir_path.directory()[:]) {
    ([x, .. xs], [y, .. ys]) if x == y => continue (xs, ys)
    (_, ys) => break ys
  }
  let pkg_name = if pkg.length() == 0 {
    self.name()
  } else {
    self.name() + "/" + pkg.join("/")
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
pub async fn Module::diagnostics(self : Module) -> @diagnostics.Diagnostics {
  let diags = @diagnostics.Diagnostics::new()
  for _, pkg in self.packages {
    diags.append(pkg.diagnostics())
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
