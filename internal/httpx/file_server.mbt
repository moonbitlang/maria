///|
struct FileServer {
  path : String
}

///|
pub fn FileServer::new(path : StringView) -> FileServer {
  FileServer::{ path: path.to_string() }
}

///|
pub async fn FileServer::handle(
  self : FileServer,
  r : RequestReader,
  w : ResponseWriter,
) -> Unit {
  guard r.method_ is Get else {
    w.write_header(@status.MethodNotAllowed)
    return
  }
  let path = match r.path {
    "/" => @path.join(self.path, "index.html")
    ['/', .. path] => @path.join(self.path, path)
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
  if !exists {
    w.write_header(@status.NotFound)
    w.write("404 Not Found")
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
