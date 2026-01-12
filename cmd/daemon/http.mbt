///|
/// HTTP error wrapper used to bubble failures to the HTTP layer.
priv suberror HttpError {
  HttpError(code~ : Int, reason~ : String, body~ : String)
}

///|
/// Constructs an `HttpError` carrying a JSON body that will be stringified.
/// Use for structured error responses in handlers.
fn json_error(code : Int, reason : String, body : Json) -> HttpError {
  HttpError(code~, reason~, body=body.stringify())
}

///|
/// Constructs an `HttpError` with a plain-text body.
fn text_error(code : Int, reason : String, body : String) -> HttpError {
  HttpError(code~, reason~, body~)
}

///|
/// Reads a static HTML file. Returns 404 HTML on ENOENT.
async fn html_read_file(path : String) -> String {
  @fsx.read_file(path) catch {
    @os_error.OSError(_) as os_error if os_error.is_ENOENT() =>
      raise text_error(404, "NotFound", "<h1>404 Not Found</h1>")
    error => raise error
  }
}

///|
/// Serves a static asset from the daemon's `serve` directory.
///
/// Endpoint: GET /{path}
///
/// Request:
/// - Path param: `path` within the configured `serve` directory.
///
/// Response:
/// - 200 OK: appropriate `Content-Type` and file content.
/// - 404 NotFound: when the path is outside `serve` or not a file.
async fn serve_static_file(
  w : @httpx.ResponseWriter,
  serve~ : String,
  path~ : String,
) -> Unit {
  if @pathx.join(serve, path) is path &&
    (try? @fsx.exists_as_file(path)) is Ok(true) {
    let content_type = match @pathx.ext(path) {
      ".js" => "application/javascript"
      ".css" => "text/css"
      ".html" => "text/html"
      ".png" => "image/png"
      ".jpg" | ".jpeg" => "image/jpeg"
      ".gif" => "image/gif"
      _ => "application/octet-stream"
    }
    logger.info("Serving static file: \{path}")
    let content = html_read_file(path)
    w.header().set("Content-Type", content_type)
    w.write_header(200)
    w.write(content)
  } else {
    raise json_error(404, "NotFound", {
      "error": {
        "code": -1,
        "message": "Unknown endpoint: \{path}",
        "metadata": { "method": @http.Get.to_string(), "path": path },
      },
    })
  }
}
