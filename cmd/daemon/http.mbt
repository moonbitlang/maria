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
async fn html_read_file(path : String) -> String {
  @fsx.read_file(path) catch {
    @os_error.OSError(_) as os_error if os_error.is_ENOENT() =>
      raise text_error(404, "NotFound", "<h1>404 Not Found</h1>")
    error => raise error
  }
}

///|
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
    println("[INFO] (Daemon) Serving static file: \{path}")
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
