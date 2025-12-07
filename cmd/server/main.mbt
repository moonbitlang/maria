///|
priv suberror HttpError {
  HttpError(code~ : Int, reason~ : String, body~ : String)
}

///|
fn json_error(code : Int, reason : String, body : Json) -> HttpError {
  HttpError(code~, reason~, body=body.stringify())
}

///|
fn text_error(code : Int, reason : String, body : String) -> HttpError {
  HttpError(code~, reason~, body~)
}

///|
pub(all) struct Register {
  host : String
  port : Int
  id : String
}

///|
async fn html_read_file(path : String) -> String {
  @fsx.read_file(path) catch {
    @os_error.OSError(_) as os_error if os_error.is_ENOENT() =>
      raise text_error(404, "NotFound", "<h1>404 Not Found</h1>")
    error => raise error
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
  let response : Json = { "modules": modules_json }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.stringify())
}

///|
async fn publish_moonbit_module(
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request_json = r.body.read_all().json() catch {
      error =>
        raise json_error(400, "BadRequest", {
          "error": {
            "code": -1,
            "message": "Invalid JSON in request body: \{error}",
          },
        })
    }
  guard request_json is { "module": { "path": String(path), .. }, .. } else {
    raise json_error(400, "BadRequest", {
      "error": {
        "code": -1,
        "message": "Missing 'module.path' field in request body",
      },
    })
  }
  let process = @spawn.spawn("moon", ["publish"], cwd=path) catch {
    error =>
      raise json_error(500, "InternalServerError", {
        "error": {
          "code": -1,
          "message": "Failed to spawn 'moon publish' for '\{path}': \{error}",
        },
      })
  }
  let module_ = @moon.Module::load(path) catch {
    error =>
      raise json_error(404, "NotFound", {
        "error": {
          "code": -1,
          "message": "No MoonBit module found in path '\{path}'",
          "metadata": error.to_json(),
        },
      })
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
    w.header().set("Content-Type", "application/json")
    w.write_header(201)
    w.write(response.stringify())
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
    w.header().set("Content-Type", "application/json")
    w.write_header(500)
    w.write(response.stringify())
  }
}

///|
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
  let server = Server::new(model?, register?, serve~, port~, web_search~)
  server.start()
}
