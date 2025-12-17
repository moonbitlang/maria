///|
/// Connection details used to register the local server with a daemon.
pub(all) struct RegisterInfo {
  host : String
  port : Int
  id : String
}

///|
/// Recursively walks the provided directory tree and records every folder that
/// contains a `moon.mod.json` so it can be turned into a `@moon.Module`.
async fn collect_modules(
  directory : String,
  modules : Array[@moon.Module],
) -> Unit {
  let moon_mod_json = @pathx.join(directory, "moon.mod.json")
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
/// Responds with metadata for each MoonBit module visible from the server's
/// working directory.
async fn Server::list_moonbit_modules(
  server : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let modules = []
  collect_modules(server.cwd, modules)
  let modules_json : Array[Json] = []
  for mod in modules {
    modules_json.push({
      "path": mod.path,
      "name": mod.name,
      "version": mod.version,
      "description": mod.description,
    })
  }
  w.send_json(code=200, { "modules": modules_json })
}

///|
/// Spawns `moon publish` for the requested module directory and returns either
/// the published module metadata or a structured error payload.
async fn publish_moonbit_module(
  request_json : Json,
  w : @httpx.ResponseWriter,
) -> Unit {
  guard request_json is { "module": { "path": String(path), .. }, .. } else {
    raise @httpx.JsonError::new(
      @status.BadRequest,
      "Missing 'module.path' field in request body",
    )
  }
  let process = @spawn.spawn("moon", ["publish"], cwd=path) catch {
    error =>
      raise @httpx.JsonError::from_error(
        @status.InternalServerError,
        error,
        message="Failed to spawn 'moon publish' for '\{path}': \{error}",
      )
  }
  let module_ = @moon.Module::load(path) catch {
    error =>
      raise @httpx.JsonError::from_error(
        @status.NotFound,
        error,
        message="No MoonBit module found in path '\{path}'",
      )
  }
  if process.status == 0 {
    let response : Json = {
      "module": {
        "path": path,
        "name": module_.name,
        "version": module_.version,
        "description": module_.description,
      },
      "process": {
        "status": process.status,
        "stdout": process.stdout,
        "stderr": process.stderr,
      },
    }
    w.send_json(code=201, response)
  } else {
    let response : Json = {
      "error": {
        "code": -1,
        "message": "Failed to publish module at '\{path}'",
        "metadata": {
          "module": {
            "path": path,
            "name": module_.name,
            "version": module_.version,
            "description": module_.description,
          },
          "process": {
            "status": process.status,
            "stdout": process.stdout,
            "stderr": process.stderr,
          },
        },
      },
    }
    w.send_json(code=500, response)
  }
}

///|
/// CLI entry point. Parses flags, loads the requested model, and boots the
/// HTTP server with optional daemon registration.
pub async fn start(args : ArrayView[String]) -> Unit {
  let mut model = None
  let mut port = 0
  let mut serve = @os.cwd()
  let mut register_host = None
  let mut register_port = None
  let mut register_id = None
  let mut web_search = false
  loop args {
    ["-m" | "--model", m, .. args] =>
      if m.has_prefix("-") {
        fail("Expected model name after \{args[0]}")
      } else {
        model = Some(m)
        continue args
      }
    ["-p" | "--port", p, .. args] => {
      port = @strconv.parse_int(p)
      continue args
    }
    ["--register-host", d, .. args] =>
      if d.has_prefix("-") {
        fail("Expected daemon host after \{args[0]}")
      } else {
        register_host = Some(d)
        continue args
      }
    ["--register-port", dp, .. args] => {
      register_port = Some(@strconv.parse_int(dp))
      continue args
    }
    ["--register-id", du, .. args] =>
      if du.has_prefix("-") {
        fail("Expected register id after \{args[0]}")
      } else {
        register_id = Some(du)
        continue args
      }
    ["--serve", s, .. args] =>
      if s.has_prefix("-") {
        fail("Expected serve path after \{args[0]}")
      } else {
        serve = s
        continue args
      }
    ["--web-search", .. args] => {
      web_search = true
      continue args
    }
    [unknown, ..] => {
      let error : Json = {
        "error": { "code": -1, "message": "Unknown argument: \{unknown}" },
      }
      println(error.stringify())
    }
    [] => break
  }
  let register = match (register_host, register_port, register_id) {
    (Some(host), Some(port), Some(id)) => Some({ host, port, id })
    (None, None, None) => None
    _ =>
      fail(
        "--register-host, --register-port, and --register-id must be provided together",
      )
  }
  Server::new(model?, register?, serve~, port~, web_search~).start()
}
