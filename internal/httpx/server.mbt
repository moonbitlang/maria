///|
/// Thin wrapper around `@http.Server` providing a simpler API.
///
/// `Server` binds to the given host/port and exposes helpers for querying
/// the bound port and running a `httpx` handler loop.
struct Server {
  server : @http.Server
  port : Int
}

///|
/// Closes the underlying HTTP server and stops accepting new connections.
pub fn Server::close(self : Server) -> Unit {
  self.server.close()
}

///|
/// Creates a new HTTP server bound to `host:port`.
///
/// Parameters:
///
/// * `host` : Hostname or IP address to bind.
/// * `port` : Preferred TCP port (0 lets the OS choose a free port).
/// * `dual_stack` : Enable IPv4/IPv6 dual-stack when supported.
/// * `reuse_addr` : Enable address reuse on the socket.
///
/// The actual bound port can be retrieved via `Server::port`.
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
/// Returns the TCP port the server is currently listening on.
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
      (handler.0)(r, w) catch {
        JsonError(_) as error => error.write(w)
        error => raise error
      }
    },
    allow_failure=true,
  )
}
