///|
test "Method::Show" {
  inspect(@httpx.Method::Get, content="GET")
  inspect(@httpx.Method::Head, content="HEAD")
  inspect(@httpx.Method::Post, content="POST")
  inspect(@httpx.Method::Put, content="PUT")
  inspect(@httpx.Method::Delete, content="DELETE")
  inspect(@httpx.Method::Connect, content="CONNECT")
  inspect(@httpx.Method::Options, content="OPTIONS")
  inspect(@httpx.Method::Trace, content="TRACE")
  inspect(@httpx.Method::Patch, content="PATCH")
}
