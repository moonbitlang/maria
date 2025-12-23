///|
/// Internal routing entry storing the handler and captured parameter names.
priv struct Route {
  handle : Handler
  names : Array[StringView]
}

///|
pub async fn Router::handle(
  self : Router,
  r : RequestReader,
  w : ResponseWriter,
) -> Unit {
  (self.handler)(r, w)
}

///|
pub fn Router::handler(self : Router) -> Handler {
  self.handler
}

///|
pub fn Router::middleware(self : Router) -> Middleware {
  self.middleware
}

///|
fn Route::new(handle : Handler) -> Route {
  Route::{ handle, names: [] }
}

///|
priv struct Layer {
  routes : MethodMap[Route]
  matches : Map[StringView, Layer]
  mut default : Layer?
}

///|
fn Layer::new() -> Layer {
  Layer::{ routes: MethodMap::new(), matches: {}, default: None }
}

///|
fn Layer::add_route(
  self : Layer,
  method_ : Method,
  segments : ArrayView[StringView],
  route : Route,
) -> Unit {
  match segments {
    [] => self.routes[method_] = route
    [['{', .. name, '}'], .. segments] => {
      route.names.push(name)
      if self.default is Some(child) {
        child.add_route(method_, segments, route)
      } else {
        let child = Layer::new()
        self.default = Some(child)
        child.add_route(method_, segments, route)
      }
      for _, value in self.matches {
        value.add_route(method_, segments, route)
      }
    }
    [value, .. segments] =>
      match self.matches.get(value) {
        Some(child) => child.add_route(method_, segments, route)
        None => {
          let child = Layer::new()
          self.matches[value] = child
          child.add_route(method_, segments, route)
        }
      }
  }
}

///|
fn Layer::route(
  self : Layer,
  segments : ArrayView[StringView],
) -> (MethodMap[Route], Array[StringView])? {
  let mut curr : Array[(Layer, Array[StringView])] = [(self, [])]
  let mut next : Array[(Layer, Array[StringView])] = []
  loop segments {
    [] =>
      for r in curr {
        break Some((r.0.routes, r.1))
      } else {
        None
      }
    [segment, .. segments] => {
      for r in curr {
        if r.0.matches.get(segment) is Some(child) {
          next.push((child, r.1))
        } else if r.0.default is Some(child) {
          let values = r.1
          values.push(segment)
          next.push((child, values))
        }
      }
      curr = next
      next = []
      continue segments
    }
  }
}

///|
/// HTTP request router with method- and path-based dispatch.
///
/// `Router` matches incoming requests against registered path patterns and
/// methods, populating `RequestReader.vars` with any captured parameters.
struct Router {
  layer : Layer
  allow : MethodSet
  mut handler : Handler
  middleware : Middleware
}

///|
/// Creates a new, empty router with a default 404 handler.
///
/// The router installs a middleware that handles `OPTIONS *` requests and
/// populates `Allow` headers based on the registered routes.
pub fn Router::new() -> Router {
  let layer = Layer::new()
  let allow = MethodSet::new()
  let middleware : Middleware = k => (r, w) => match (r.method_, r.path) {
    (Options, "*") => {
      w
      .header()
      .set(
        "Allow",
        allow.iterator().map(method_ => method_.to_string()).join(", "),
      )
      w.write_header(@status.NoContent)
    }
    (method_, ['/', .. path]) => {
      // Strip query string before matching route
      let path_without_query : StringView = path
        .split("?")
        .head()
        .unwrap_or(path)
      let segments = path_without_query.split("/").collect()
      guard layer.route(segments) is Some((routes, values)) else { k(r, w) }
      guard routes.get(method_) is Some(route) else {
        w
        .header()
        .set(
          "Allow",
          routes
          .keys()
          .iterator()
          .map(method_ => method_.to_string())
          .join(", "),
        )
        w.write_header(@status.MethodNotAllowed)
        return
      }
      for i in 0..<route.names.length() {
        let name = route.names[i]
        let value = values[i]
        r.vars[name] = value
      }
      (route.handle.0)(r, w)
    }
    (_, _) => w.write_header(@status.BadRequest)
  }
  Router::{ layer, allow, handler: middleware(not_found), middleware }
}

///|
/// Registers a new handler for the given HTTP method and path pattern.
///
/// Parameters:
///
/// * `method_` : HTTP method to match.
/// * `path` : Route path starting with `/`, optionally containing
///   `{name}` segments which are exposed via `RequestReader.vars`.
pub fn Router::add_handler(
  self : Router,
  method_ : Method,
  path : StringView,
  handler : Handler,
) -> Unit {
  guard path is ['/', .. path] else {
    abort("Path must start with '/', got \{path}")
  }
  let segments = path.split("/").collect()
  let route = Route::new(handler)
  self.allow[method_] = true
  self.layer.add_route(method_, segments, route)
}

///|
/// Sets a custom handler to be used when no route matches.
///
/// The handler is wrapped by the router's middleware chain.
pub fn Router::set_not_found_handler(self : Router, handler : Handler) -> Unit {
  self.handler = (self.middleware)(handler)
}

///|
test "Layer::add_handler" {
  let route : Route = Route::new((_, _) => ())
  let layer = Layer::new()
  layer.add_route(Get, ["v1", "user", "{id}", "messages"], route)
  @json.inspect(layer.matches.keys(), content=["v1"])
  @json.inspect(layer.matches["v1"].matches.keys(), content=["user"])
  @json.inspect(
    layer.matches["v1"].matches["user"].default is Some(_),
    content=true,
  )
  @json.inspect(
    layer.matches["v1"].matches["user"].default.unwrap().matches.keys(),
    content=["messages"],
  )
  @json.inspect(
    layer.matches["v1"].matches["user"].default.unwrap().matches["messages"].routes.keys(),
    content=["Get"],
  )
  @json.inspect(
    layer.matches["v1"].matches["user"].default.unwrap().matches["messages"].routes[Get].names,
    content=["id"],
  )
}

///|
test "Layer::route" {
  let route : Route = Route::new((_, _) => ())
  let layer = Layer::new()
  layer.add_route(Get, ["v1", "user", "{id}", "messages"], route)
  @json.inspect(
    layer.route(["v1", "user", "42", "messages"]) is Some(_),
    content=true,
  )
  @json.inspect(
    layer.route(["v1", "user", "0", "messages"]) is Some(_),
    content=true,
  )
  layer.add_route(Post, ["hello"], route)
  @json.inspect(layer.route(["hello"]) is Some(_), content=true)
}
