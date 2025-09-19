///|
struct Package {
  name : String
  path : String
  files : Map[String, File]
  mtime : Int64
} derive(Show)

///|
pub impl ToJson for Package with to_json(self : Package) -> Json {
  {
    "name": self.name.to_json(),
    "path": self.path.to_json(),
    "files": self.files,
  }
}

///|
fn Package::new(path~ : String, name~ : String) -> Package raise {
  let mtime = @fs.stat(path).mtime()
  Package::{ name, path, files: {}, mtime }
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
pub fn Package::add_diagnostic(self : Package, diagnostic : Diagnostic) -> Unit {
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
  cwd? : StringView,
) -> Array[Diagnostic] {
  check(package_=self, patch_file?, target_dir?, cwd?)
}

///|
async fn Package::interface(self : Package) -> String? {
  let mbti_path = @path.join(self.path, "pkg.generated.mbti")
  if @fs.exists(mbti_path) {
    Some(@fs.read_file(mbti_path))
  } else {
    let entries = @fs.list_directory(self.path)
    for entry in entries {
      if entry.kind is Regular && entry.name.has_suffix(".mbti") {
        return Some(@fs.read_file(@path.join(self.path, entry.name)))
      }
    } else {
      None
    }
  }
}

///|
fn Package::diagnostics(self : Package) -> Iter[Diagnostic] {
  let mut diagnostics = Iter::empty()
  for file in self.files.values() {
    diagnostics = diagnostics.concat(file.diagnostics())
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
