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
  let schema = string[:protocol_len].to_owned()
  let uri = string[protocol_len + 3:]
  let (host, path) = if uri.find("/") is Some(i) {
    (uri[:i].to_owned(), uri[i:].to_owned())
  } else {
    (uri.to_owned(), "/".to_string())
  }
  { schema, host, path: if path == "" { "/" } else { path } }
}
