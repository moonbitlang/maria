///|
priv struct Uri {
  schema : String
  host : String
  path : String
}

///|
priv suberror InvalidUri

///|
fn Uri::parse(string : String) -> Uri raise InvalidUri {
  guard string.find("://") is Some(protocol_len) else { raise InvalidUri }
  let schema = try! string[:protocol_len].to_string()
  let uri = string[protocol_len + 3:] catch { _ => raise InvalidUri }
  let (host, path) = if uri.find("/") is Some(i) {
    (try! uri[:i].to_string(), try! uri[i:].to_string())
  } else {
    (uri.to_string(), "/".to_string())
  }
  { schema, host, path: if path == "" { "/" } else { path } }
}
