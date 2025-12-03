///|
priv struct MoonbitModules {
  modules : Array[@moon.Module]
}

///|
impl ToJson for MoonbitModules with to_json(self : MoonbitModules) -> Json {
  {
    "modules": Json::array(
      self.modules.map(mod => {
        "path": mod.path,
        "name": mod.name,
        "version": mod.version,
        "description": mod.description,
      }),
    ),
  }
}

///|
async fn collect_modules(
  directory : String,
  modules : Array[@moon.Module],
) -> Unit {
  let moon_mod_json = @path.join(directory, "moon.mod.json")
  if @fsx.exists(moon_mod_json) {
    modules.push(@moon.Module::load(directory))
  } else {
    let entries = @fsx.list_directory(directory)
    for entry in entries {
      if entry.kind is Directory {
        collect_modules(entry.path, modules)
      }
    }
  }
}

///|
async fn Server::list_moonbit_modules(
  server : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let w = JsonResponseWriter::new(w)
  let modules = []
  collect_modules(server.cwd, modules)
  w.write_header(200)
  w.write(MoonbitModules::{ modules, })
}
