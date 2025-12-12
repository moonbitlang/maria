///|
struct Import {
  path : String
  alias_ : String?
} derive(Show)

///|
pub impl @json.FromJson for Import with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Import {
  match json {
    String(path) => Import::{ path, alias_: None }
    { "path": String(path), "alias": String(alias_), .. } =>
      Import::{ path, alias_: Some(alias_) }
    _ => raise @json.JsonDecodeError((json_path, "Invalid Import"))
  }
}

///|
struct Package {
  name : String
  path : String
  files : Map[String, File]
  mtime : Int64
  is_main : Bool
  import_ : Array[Import]
  test_import : Array[Import]
  wbtest_import : Array[Import]
} derive(Show)

///|
pub impl ToJson for Package with to_json(self : Package) -> Json {
  { "name": self.name, "path": self.path, "files": self.files }
}

///|
async fn Package::new(path~ : String, name~ : String) -> Package {
  let moon_pkg_path = @pathx.join(path, "moon.pkg.json")
  let import_ = []
  let test_import = []
  let wbtest_import = []
  let mut is_main = false
  let moon_pkg_text = @fsx.read_file(moon_pkg_path)
  try {
    if @json.parse(moon_pkg_text) is Object(moon_pkg_json) {
      if moon_pkg_json.get("import") is Some(import_json) {
        import_.append((@json.from_json(import_json) : Array[Import])) catch {
          _ => ()
        }
      }
      if moon_pkg_json.get("test-import") is Some(test_import_json) {
        test_import.append((@json.from_json(test_import_json) : Array[Import])) catch {
          _ => ()
        }
      }
      if moon_pkg_json.get("wbtest-import") is Some(wbtest_import_json) {
        wbtest_import.append(
          (@json.from_json(wbtest_import_json) : Array[Import]),
        ) catch {
          _ => ()
        }
      }
      if moon_pkg_json.get("is-main") is Some(is_main_json) {
        try {
          is_main = @json.from_json(is_main_json)
        } catch {
          _ => ()
        }
      }
      if moon_pkg_json.get("is_main") is Some(is_main_json) {
        try {
          is_main = @json.from_json(is_main_json)
        } catch {
          _ => ()
        }
      }
    }
  } catch {
    _ => ()
  }
  let mtime = @fsx.stat(path).mtime()
  Package::{
    name,
    path,
    files: {},
    mtime,
    is_main,
    import_,
    test_import,
    wbtest_import,
  }
}

///|
fn Package::clear_diagnostics(self : Package) -> Unit {
  for file in self.files.values() {
    file.clear_diagnostics()
  }
}

///|
pub fn Package::name(self : Package) -> String {
  self.name
}

///|
pub fn Package::path(self : Package) -> String {
  self.path
}

///|
async fn Package::add_file(self : Package, file : String) -> Unit {
  match self.files.get(file) {
    None => {
      let f = File::new(file)
      self.files[f.path] = f
      f.load()
    }
    Some(file) => file.load()
  }
}

///|
fn Package::files(self : Package) -> Iter[File] {
  self.files.values()
}

///|
pub fn Package::add_diagnostic(
  self : Package,
  diagnostic : @diagnostics.Diagnostic,
) -> Unit {
  guard self.files.get(diagnostic.loc.path) is Some(file) else {
    println(
      "Warning: Diagnostic path \{diagnostic.loc.path} not found in package \{self.name}",
    )
  }
  file.add_diagnostic(diagnostic)
}

///|
pub async fn Package::check(
  self : Package,
  patch_file? : StringView,
  target_dir? : StringView,
  cwd~ : StringView,
) -> @diagnostics.Diagnostics {
  check(package_path=self.path, patch_file?, target_dir?, cwd~)
}

///|
pub async fn Package::interface(self : Package) -> String? {
  let mbti_path = @pathx.join(self.path, "pkg.generated.mbti")
  if @fsx.exists(mbti_path) {
    Some(@fsx.read_file(mbti_path))
  } else {
    let entries = @fsx.list_directory(self.path)
    for entry in entries {
      if entry.kind is Regular && entry.name.has_suffix(".mbti") {
        return Some(@fsx.read_file(@pathx.join(self.path, entry.name)))
      }
    } else {
      None
    }
  }
}

///|
fn Package::diagnostics(self : Package) -> @diagnostics.Diagnostics {
  let diagnostics = @diagnostics.Diagnostics::new()
  for file in self.files.values() {
    diagnostics.append(file.diagnostics())
  }
  diagnostics
}

///|
pub struct PackageView {
  module_ : Module
  name : String
}

///|
pub impl ToJson for PackageView with to_json(self : PackageView) -> Json {
  self.package_().to_json()
}

///|
pub fn PackageView::package_(self : PackageView) -> Package {
  self.module_.packages[self.name]
}

///|
pub async fn PackageView::info(self : PackageView) -> Unit {
  self.module_.info(package_=self.name)
}

///|
pub async fn PackageView::interface(self : PackageView) -> String {
  let pkg = self.package_()
  match pkg.interface() {
    Some(interface) => interface
    None => {
      self.info() catch {
        error =>
          match pkg.interface() {
            None => raise error
            Some(interface) => return interface
          }
      }
      match pkg.interface() {
        Some(interface) => interface
        None => fail("Failed to load interface for package \{self.name}")
      }
    }
  }
}

///|
pub fn PackageView::is_main(self : PackageView) -> Bool {
  let package_ = self.package_()
  package_.is_main
}

///|
pub fn PackageView::name(self : PackageView) -> String {
  self.package_().name
}

///|
pub fn PackageView::files(self : PackageView) -> Iter[File] {
  self.package_().files()
}
