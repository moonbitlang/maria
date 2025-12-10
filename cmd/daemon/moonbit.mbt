///|
async fn publish_moonbit_module(
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let request = r.body.read_all().binary()
  let request_text : String = @encoding/utf8.decode(request) catch {
    // TODO(upstream): impl Show for @encoding/utf8.Malformed
    @encoding/utf8.Malformed(bytes) =>
      raise json_error(400, "BadRequest", {
        "error": {
          "code": -1,
          "message": "Invalid UTF-8 in request body: \{bytes}",
        },
      })
  }
  let request_json = @json.parse(request_text) catch {
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
          "message": "No MoonBit module found in path '\{path}': \{error}",
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
