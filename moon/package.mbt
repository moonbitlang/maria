///|
struct Package {
  name : String
  path : String
  files : Map[String, File]
  mtime : Int64
} derive(Show, ToJson)

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
pub async fn Package::interface(self : Package) -> String {
  let mbti_path = @path.join(self.path, "pkg.generated.mbti")
  if !@fs.exists(mbti_path) {
    @fs.read_file(mbti_path)
  } else {
    let files = self.files().collect()
    for file in files {
      if file.path.has_suffix(".mbti") {
        return @fs.read_file(file.path)
      }
    } else {
      ""
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
