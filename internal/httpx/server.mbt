///|
struct Server {
  server : @http.Server
  port : Int
}

///|
pub fn Server::close(self : Server) -> Unit {
  self.server.close()
}

///|
pub fn Server::new(
  host : String,
  port : Int,
  dual_stack? : Bool = true,
  reuse_addr? : Bool = false,
) -> Server raise {
  let server = @http.Server::new(
    @socket.Addr::parse("\{host}:\{port}"),
    dual_stack~,
    reuse_addr~,
  )
  let port = server.addr().port()
  Server::{ server, port }
}

///|
pub fn Server::port(self : Server) -> Int {
  self.port
}

///|
/// Starts the HTTP server and begins listening for incoming connections.
///
/// Parameters:
///
/// * `self` : The server instance to start.
/// * `handler` : The request handler function that processes incoming HTTP requests.
///
/// This function never returns.
pub async fn Server::serve(self : Server, handler : Handler) -> Unit {
  self.server.run_forever(
    (rh, rb, w) => {
      let method_ = Method::from_async_http(rh.meth)
      let r : RequestReader = { body: rb, method_, path: rh.path, vars: {} }
      let w : ResponseWriter = ResponseWriter::new(w)
      (handler.0)(r, w)
    },
    allow_failure=true,
  )
}
