///|
/// Simple static file server rooted at a given directory.
///
/// `FileServer` exposes a middleware and handler that can be mounted into a
/// router to serve static assets such as HTML, JS and CSS files.
struct FileServer {
  path : String
  middleware : Middleware
  mut handler : Handler
}

///|
/// Returns the current handler used to serve static files.
pub fn FileServer::handler(self : FileServer) -> Handler {
  self.handler
}

///|
/// Returns the middleware that wraps the static file handler.
pub fn FileServer::middleware(self : FileServer) -> Middleware {
  self.middleware
}

///|
/// Returns the filesystem path that this file server is rooted at.
pub fn FileServer::path(self : FileServer) -> StringView {
  self.path.view()
}

///|
/// Creates a new file server rooted at the given directory.
///
/// The resulting middleware only serves `GET` requests and falls back to the
/// downstream handler when a file does not exist.
pub fn FileServer::new(path : StringView) -> FileServer {
  let self_path = path.to_string()
  let middleware : Middleware = k => {
    (r, w) => {
      guard r.method_ is Get else {
        w.write_header(@status.MethodNotAllowed)
        return
      }
      let path = match r.path {
        "/" => @pathx.join(self_path, "index.html")
        ['/', .. path] => @pathx.join(self_path, path)
        _ => {
          w.write_header(@status.BadRequest)
          return
        }
      }
      let exists = @fsx.exists_as_file(path) catch {
        error => {
          w.write_header(@status.InternalServerError)
          w.write("Internal Server Error: \{error}")
          return
        }
      }
      guard exists else {
        k(r, w)
        return
      }
      let content = @fsx.read_file(path) catch {
        error => {
          w.write_header(@status.InternalServerError)
          w.write("Internal Server Error: \{error}")
          return
        }
      }
      let content_type = match @pathx.ext(path) {
        ".js" => "application/javascript"
        ".css" => "text/css"
        ".html" => "text/html"
        ".png" => "image/png"
        ".jpg" | ".jpeg" => "image/jpeg"
        ".gif" => "image/gif"
        _ => "application/octet-stream"
      }
      w.header().set("Content-Type", content_type)
      w.write_header(@status.Ok)
      w.write(content)
    }
  }
  FileServer::{
    path: path.to_string(),
    middleware,
    handler: middleware(not_found),
  }
}

///|
/// Handles a single HTTP request using the configured static file handler.
pub async fn FileServer::handle(
  self : FileServer,
  r : RequestReader,
  w : ResponseWriter,
) -> Unit {
  (self.handler)(r, w)
}

///|
/// Overrides the handler used when a requested file is not found.
///
/// The handler is wrapped by the file server's middleware.
pub fn FileServer::set_not_found_handler(
  self : FileServer,
  handler : Handler,
) -> Unit {
  self.handler = (self.middleware)(handler)
}
