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
async fn run_server(
  port~ : Int,
  f : async (@http.Request, @http.ServerConnection) -> Unit,
) -> Unit {
  @http.run_server(try! @socket.Addr::parse("[::]:\{port}"), (conn, _) => for {
    try {
      let request = conn.read_request()
      println("[INFO] Received request: \{request.meth} \{request.path}")
      f(request, conn)
    } catch {
      HttpError(code~, reason~, body~) =>
        conn
        ..send_response(code, reason, extra_headers={
          "Content-Type": "application/json",
        })
        ..write(body)
        ..end_response()
      error => raise error
    }
  })
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
async fn main {
  let args = @os.args()
  let mut model = None
  let mut port = 8080
  let mut serve = @os.cwd()
  loop args[1:] {
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
    ["--serve", s, .. args] =>
      if s.has_prefix("-") {
        fail("Expected serve path after \{args[0]}")
      } else {
        serve = s
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
  let channel = @aqueue.new()
  let logger = @pino.logger("server", @pino.Transport::chan(channel))
  let message_queue = @aqueue.new()
  let maria = @maria.Maria::new(model?, logger~)
  @async.with_task_group(group => {
    group.spawn_bg(
      () => while true {
        let message = message_queue.get()
        maria.agent.add_message(message)
        maria.agent.start() catch {
          error => {
            logger.error("MariaFailed", {
              "error": {
                "code": -1,
                "message": error.to_string(),
                "metadata": error.to_json(),
              },
            })
            raise error
          }
        }
      },
      allow_failure=true,
    )
    run_server(port~, (request, conn) => match (request.meth, request.path) {
      (Get, "/") => {
        let index_html = html_read_file(@path.join(serve, "index.html"))
        conn
        ..send_response(200, "OK", extra_headers={ "Content-Type": "text/html" })
        ..write(index_html)
        ..end_response()
      }
      (Get, "/script.js") => {
        let script_js = html_read_file(@path.join(serve, "script.js"))
        conn
        ..send_response(200, "OK", extra_headers={
          "Content-Type": "application/javascript",
        })
        ..write(script_js)
        ..end_response()
      }
      (Get, "/v1/events") => {
        conn.send_response(200, "OK", extra_headers={
          "Content-Type": "text/event-stream",
        })
        for {
          let event = channel.get()
          conn
          ..write("event: maria\n")
          ..write("data: \{event.stringify()}\n\n")
          ..flush()
        }
      }
      (Post, "/v1/message") => {
        let body_data = conn.read_all().binary()
        let body_text : String = @encoding/utf8.decode(body_data) catch {
          // TODO(upstream): impl Show for @encoding/utf8.Malformed
          @encoding/utf8.Malformed(bytes) =>
            raise json_error(400, "BadRequest", {
              "error": {
                "code": -1,
                "message": "Invalid UTF-8 in request body: \{bytes}",
              },
            })
        }
        let body_json = @json.parse(body_text) catch {
          error =>
            raise json_error(400, "BadRequest", {
              "error": {
                "code": -1,
                "message": "Invalid JSON in request body: \{error}",
              },
            })
        }
        guard body_json is { "message": message, .. } else {
          raise json_error(400, "BadRequest", {
            "error": {
              "code": -1,
              "message": "Missing 'message' field in request body",
            },
          })
        }
        let message : @openai.ChatCompletionMessageParam = @json.from_json(
          message,
        ) catch {
          @json.JsonDecodeError(_) as error =>
            raise json_error(400, "BadRequest", {
              "error": {
                "code": -1,
                "message": "Invalid 'message' field: \{error}",
              },
            })
        }
        message_queue.put(message)
        let response : Json = {}
        conn
        ..send_response(200, "OK", extra_headers={
          "Content-Type": "application/json",
        })
        ..write(response.stringify())
        ..end_response()
      }
      _ =>
        raise json_error(404, "NotFound", {
          "error": {
            "code": -1,
            "message": Failure("Unknown endpoint: \{request.path}").to_string(),
          },
        })
    })
  })
}
