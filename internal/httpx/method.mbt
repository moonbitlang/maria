///|
/// HTTP request methods supported by the `httpx` router.
pub(all) enum Method {
  Get
  Head
  Post
  Put
  Delete
  Connect
  Options
  Trace
  Patch
} derive(Eq, Compare, Hash, ToJson)

///|
pub impl Show for Method with to_string(self : Method) -> String {
  match self {
    Method::Get => "GET"
    Method::Head => "HEAD"
    Method::Post => "POST"
    Method::Put => "PUT"
    Method::Delete => "DELETE"
    Method::Connect => "CONNECT"
    Method::Options => "OPTIONS"
    Method::Trace => "TRACE"
    Method::Patch => "PATCH"
  }
}

///|
pub impl Show for Method with output(self : Method, out : &Logger) -> Unit {
  out.write_string(self.to_string())
}

///|
/// Array containing all supported HTTP methods.
pub let methods : Array[Method] = [
  Method::Get,
  Method::Head,
  Method::Post,
  Method::Put,
  Method::Delete,
  Method::Connect,
  Method::Options,
  Method::Trace,
  Method::Patch,
]

///|
fn Method::from_async_http(method_ : @http.RequestMethod) -> Method {
  match method_ {
    @http.RequestMethod::Get => Method::Get
    @http.RequestMethod::Head => Method::Head
    @http.RequestMethod::Post => Method::Post
    @http.RequestMethod::Put => Method::Put
    @http.RequestMethod::Delete => Method::Delete
    @http.RequestMethod::Connect => Method::Connect
    @http.RequestMethod::Options => Method::Options
    @http.RequestMethod::Trace => Method::Trace
    @http.RequestMethod::Patch => Method::Patch
  }
}

///|
/// Converts a `Method` into the corresponding `@http.RequestMethod` value.
pub fn Method::to_http(self : Method) -> @http.RequestMethod {
  match self {
    Method::Get => @http.RequestMethod::Get
    Method::Head => @http.RequestMethod::Head
    Method::Post => @http.RequestMethod::Post
    Method::Put => @http.RequestMethod::Put
    Method::Delete => @http.RequestMethod::Delete
    Method::Connect => @http.RequestMethod::Connect
    Method::Options => @http.RequestMethod::Options
    Method::Trace => @http.RequestMethod::Trace
    Method::Patch => @http.RequestMethod::Patch
  }
}
