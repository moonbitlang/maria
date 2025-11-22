///|
struct Server {
  tcp_server : @socket.TcpServer
  port : Int
}

///|
pub fn Server::close(self : Server) -> Unit {
  self.tcp_server.close()
}

///|
pub fn Server::new(
  host : String,
  port : Int,
  dual_stack? : Bool = true,
  reuse_addr? : Bool = false,
) -> Server raise {
  let tcp_server = @socket.TcpServer::new(
    @socket.Addr::parse("\{host}:\{port}"),
    dual_stack~,
    reuse_addr~,
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
        let r = conn.read_request()
        let close_conn = if r.headers.get("connection") is Some(connection) {
          connection.to_lower() == "close"
        } else {
          false
        }
        let method_ = Method::from_async_http(r.meth)
        let r : RequestReader = { body: conn, method_, path: r.path, vars: {} }
        let w : ResponseWriter = ResponseWriter::new(conn)
        try (handler.0)(r, w) catch {
          error => {
            conn.end_response()
            raise error
          }
        } noraise {
          _ => {
            conn.end_response()
            if close_conn {
              break
            }
          }
        }
      }
    },
    allow_failure=true,
  )
}
