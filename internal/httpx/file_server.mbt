///|
struct FileServer {
  path : String
  middleware : Middleware
  mut handler : Handler
}

///|
pub fn FileServer::handler(self : FileServer) -> Handler {
  self.handler
}

///|
pub fn FileServer::middleware(self : FileServer) -> Middleware {
  self.middleware
}

///|
pub fn FileServer::path(self : FileServer) -> StringView {
  self.path.view()
}

///|
pub fn FileServer::new(path : StringView) -> FileServer {
  let self_path = path.to_string()
  let middleware : Middleware = k => (r, w) => {
    guard r.method_ is Get else {
      w.write_header(@status.MethodNotAllowed)
      return
    }
    let path = match r.path {
      "/" => @path.join(self_path, "index.html")
      ['/', .. path] => @path.join(self_path, path)
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
    let content_type = match @path.ext(path) {
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
  FileServer::{
    path: path.to_string(),
    middleware,
    handler: middleware(not_found),
  }
}

///|
pub async fn FileServer::handle(
  self : FileServer,
  r : RequestReader,
  w : ResponseWriter,
) -> Unit {
  (self.handler)(r, w)
}

///|
pub async fn FileServer::set_not_found_handler(
  self : FileServer,
  handler : Handler,
) -> Unit {
  self.handler = (self.middleware)(handler)
}
