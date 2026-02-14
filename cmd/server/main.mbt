///|
priv suberror HttpError {
  HttpError(code~ : Int, reason~ : String, body~ : String)
} derive(Show, ToJson)

///|
fn json_error(code : Int, reason : String, body : Json) -> HttpError {
  HttpError(code~, reason~, body=body.stringify())
}

///|
fn text_error(code : Int, reason : String, body : String) -> HttpError {
  HttpError(code~, reason~, body~)
}

///|
/// Connection details used to register the local server with a daemon.
pub(all) struct RegisterInfo {
  host : String
  port : Int
  id : String
}

///|
/// Loads the static HTML shell used by the playground UI and surfaces a
/// user-friendly 404 page when the asset is missing.
async fn html_read_file(path : String) -> String {
  @fsx.read_file(path) catch {
    @os_error.OSError(_) as os_error if os_error.is_ENOENT() =>
      raise text_error(404, "NotFound", "<h1>404 Not Found</h1>")
    error => raise error
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
  let mut resume_id = None
  let mut name = None
  loop args {
    ["--name", n, .. args] =>
      if n.has_prefix("-") {
        fail("Expected name after \{args[0]}")
      } else {
        name = Some(n)
        continue args
      }
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
    ["--resume", rid, .. args] => {
      resume_id = Some(@uuid.parse(rid))
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
  Server::new(name?, model?, register?, serve~, port~, resume_id?, web_search~).start()
}
