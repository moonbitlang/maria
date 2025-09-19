///|
struct Module {
  path : String
  name : String
  source : String?
  packages : Map[String, Package]
  mut mtime : Int64
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
    @json.from_json(source, path=json_path.add_key("source"))
  } else {
    None
  }
  Module::{ path: "", name, source, packages: {}, mtime: 0 }
}

///|
pub async fn Module::load(path : String) -> Module {
  let moon_mod_path = @path.join(path, "moon.mod.json")
  let mod : Module = moon_mod_path
    |> @fs.read_file()
    |> @json.parse()
    |> @json.from_json()
  { ..mod, path, }
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
async fn Module::discover(self : Module) -> Unit {
  let mod_name = self.name()
  let src = self.source()
  async fn walk_directories(dir : String) -> Unit {
    let moon_pkg_path = @path.join(dir, "moon.pkg.json")
    if !@fs.exists(moon_pkg_path) {
      let entries = @fs.list_directory(self.source())
      for entry in entries {
        if entry.kind is Directory {
          walk_directories(entry.path)
        }
      }
      return
    }
    let pkg_name = if dir == src {
      mod_name
    } else {
      let rel = @path.relative(src, dir)
      "\{mod_name}/\{rel}"
    }
    let pkg = Package::new(name=pkg_name, path=dir.to_string())
    self.packages[pkg_name] = pkg
    let entries = @fs.list_directory(self.source())
    for entry in entries {
      if entry.kind is Directory {
        walk_directories(entry.path)
      } else if entry.kind is Regular {
        if entry.name.has_suffix(".mbt") || entry.name.has_suffix(".mbt.md") {
          pkg.add_file(entry.path)
        }
      }
    }
  }

  if self.mtime == 0 {
    walk_directories(src)
    self.mtime = @fs.stat(self.path).mtime()
    return
  } else {
    let pkgs = self.packages.values().collect()
    for i in 0..<pkgs.length() {
      let pkg = pkgs[i]
      if @fs.stat(pkg.path).mtime() > pkg.mtime {
        walk_directories(pkg.path)
      }
    }
  }
}

///|
async fn Module::packages(self : Module) -> Iter[Package] {
  self.discover()
  self.packages.values()
}

///|
pub async fn Module::files(self : Module) -> Iter[File] {
  let pkgs = self.packages().collect()
  let mut files = Iter::empty()
  for i in 0..<pkgs.length() {
    let pkg = pkgs[i]
    files = files.concat(pkg.files())
  }
  files
}

///|
fn Module::locate_package(self : Module, file : String) -> Package raise {
  let dir = @path.dirname(file)
  let src = self.source()
  let pkg_name = @path.relative(src, dir)
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
  self.discover()
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
