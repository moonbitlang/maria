///|
struct Server {
  tcp_server : @socket.TcpServer
  port : Int
}

///|
pub fn Server::new(host : String, port : Int) -> Server raise {
  let tcp_server = @socket.TcpServer::new(
    @socket.Addr::parse("\{host}:\{port}"),
    dual_stack=true,
  )
  let port = tcp_server.addr().port()
  Server::{ tcp_server, port }
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
  self.tcp_server.run_forever(
    (sock, _) => {
      let conn = @http.ServerConnection::new(sock)
      for {
        let request = conn.read_request()
        let method_ = Method::from_async_http(request.meth)
        let r : RequestReader = {
          body: conn,
          method_,
          path: request.path,
          vars: {},
        }
        let w : ResponseWriter = ResponseWriter::new(conn)
        try (handler.0)(r, w) catch {
          error => {
            conn.end_response()
            raise error
          }
        } noraise {
          _ => conn.end_response()
        }
      }
    },
    allow_failure=true,
  )
}
