///|
pub fn parse_url(url : String) -> (String, String) raise ClientError {
  guard url.find("://") is Some(protocol_len) else { raise InvalidUrl(url) }
  let schema = try! url[:protocol_len].to_string()
  let rest = url[protocol_len + 3:] catch { _ => raise InvalidUrl(url) }
  let (host, path) = if rest.find("/") is Some(i) {
    (try! rest[:i].to_string(), try! rest[i:].to_string())
  } else {
    (rest.to_string(), "/".to_string())
  }
  let base = "\{schema}://\{host}"
  (base, if path == "" { "/" } else { path })
}

///|
pub fn add_query_param(query : String, key : String, value : String) -> String {
  let encoded_key = encode_query_component(key)
  let encoded_value = encode_query_component(value)
  if query.is_empty() {
    "?\{encoded_key}=\{encoded_value}"
  } else {
    "\{query}&\{encoded_key}=\{encoded_value}"
  }
}
