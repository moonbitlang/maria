// URI parser implementation following RFC 3986

///|
pub struct Authority {
  mut userinfo : StringView?
  mut host : StringView
  mut port : Int?
} derive(Eq, Show)

///|
pub struct Uri {
  mut scheme : StringView
  mut authority : Authority?
  path : Array[StringView]
  mut query : StringView?
  mut fragment : StringView?
} derive(Eq, Show)

///|
suberror ParseError {
  InvalidScheme(StringView)
  InvalidPort(StringView)
  InvalidPercentEncoding(StringView)
  MissingColon
  MissingScheme
  ExtraContent(StringView)
  Eof
}

///|
fn Uri::parse_scheme(
  uri : Uri,
  source : StringView,
) -> StringView raise ParseError {
  match source {
    ['a'..='z' | 'A'..='Z', .. s] =>
      scheme~: loop s {
        ['a'..='z' | 'A'..='Z' | '0'..='9' | '+' | '-' | '.', .. s] =>
          continue scheme~ s
        [':', .. rest] as view => {
          uri.scheme = source
            .data()
            .view(
              start_offset=source.start_offset(),
              end_offset=view.start_offset(),
            )
          return rest
        }
        [_, ..] as s => raise ParseError::InvalidScheme(s)
        [] => raise ParseError::MissingColon
      }
    [_, ..] as s => raise ParseError::InvalidScheme(s)
    [] => raise ParseError::Eof
  }
}

///|
test {
  let uri = Uri::{
    scheme: "",
    authority: None,
    path: [],
    query: None,
    fragment: None,
  }
  let source = "http://example.com/path?query#fragment"
  json_inspect(
    uri.parse_scheme(source),
    content="//example.com/path?query#fragment",
  )
  json_inspect(uri.scheme, content="http")
}

///|
fn StringView::slice_until(self : StringView, other : StringView) -> StringView {
  self.view(end_offset=other.start_offset() - self.start_offset())
}

///|
fn parse_authority(
  source : StringView,
  uri : Uri,
) -> StringView raise ParseError {
  let authority = Authority::{ userinfo: None, host: "", port: None }
  uri.authority = Some(authority)
  fn parse_port(source : StringView) -> StringView raise ParseError {
    if source is [] {
      return source
    }
    let s = source
    loop (0, s) {
      (port, ['/', .. k]) => {
        authority.port = Some(port)
        return parse_path_abempty(k, uri)
      }
      (port, ['0'..='9' as c, .. k]) =>
        continue (port * 10 + c.to_int() - '0', k)
      (port, [] as s) => {
        authority.port = Some(port)
        return s
      }
      (_, [_, ..] as s) => raise ParseError::InvalidPort(s)
    }
  }

  fn parse_host(source : StringView) -> StringView raise ParseError {
    let s = source
    loop s {
      [':', .. k] as s => {
        authority.host = source.slice_until(s)
        return parse_port(k)
      }
      ['/', .. k] as s => {
        authority.host = source.slice_until(s)
        return parse_path_abempty(k, uri)
      }
      [] as s => {
        authority.host = source.slice_until(s)
        return s
      }
      [_, .. s] => continue s
    }
  }

  let s = source
  let host = @buffer.new()
  let mut port_k = None
  loop s {
    ['@', .. k] as s => {
      authority.userinfo = Some(source.slice_until(s))
      return parse_host(k)
    }
    ['/', .. k] as s =>
      if port_k is Some(port_k) {
        return parse_port(port_k)
      } else {
        authority.host = source.slice_until(s)
        return parse_path_abempty(k, uri)
      }
    [':', .. k] as s => {
      authority.host = source.slice_until(s)
      port_k = Some(k)
      continue k
    }
    [] as s => {
      authority.host = source.slice_until(s)
      return s
    }
    ['%', .. k] => {
      let mut b = 0
      let k = match k {
        ['0'..='9' as c0, .. k] => {
          b = (c0.to_int() - '0') * 16
          k
        }
        ['A'..='F' as c0, .. k] => {
          b = (c0.to_int() - 'A' + 10) * 16
          k
        }
        _ => raise ParseError::InvalidPercentEncoding(k)
      }
      let k = match k {
        ['0'..='9' as c1, .. k] => {
          b = b + (c1.to_int() - '0')
          k
        }
        ['A'..='F' as c1, .. k] => {
          b = b + (c1.to_int() - 'A' + 10)
          k
        }
        _ => raise ParseError::InvalidPercentEncoding(k)
      }
      host.write_byte(b.to_byte())
      continue k
    }
    [c, .. s] => {
      host.write_char(c)
      continue s
    }
  }
}

///|
fn parse_fragment(source : StringView, uri : Uri) -> StringView {
  let s = source
  loop s {
    [] as s => {
      uri.fragment = Some(source)
      return s
    }
    [_, .. s] => continue s
  }
}

///|
fn parse_query(source : StringView, uri : Uri) -> StringView {
  let s = source
  loop s {
    ['#', .. k] as s => {
      uri.query = Some(source.slice_until(s))
      return parse_fragment(k, uri)
    }
    [] as s => return s
    [_, .. s] => continue s
  }
}

///|
fn parse_path_abempty(source : StringView, uri : Uri) -> StringView {
  let mut path = source
  loop source {
    ['/', .. k] as s => {
      uri.path.push(path.slice_until(s))
      path = k
      continue k
    }
    ['?', .. k] as s => {
      uri.path.push(path.slice_until(s))
      return parse_query(k, uri)
    }
    ['#', .. k] as s => {
      uri.path.push(path.slice_until(s))
      uri.fragment = Some(k)
      return k
    }
    [] as s => {
      let part = path.slice_until(s)
      if !part.is_empty() {
        uri.path.push(part)
      }
      return s
    }
    [_, .. s] => continue s
  }
}

///|
pub fn Uri::parse(source : StringView) -> Uri raise ParseError {
  let uri = Uri::{
    scheme: "",
    authority: None,
    path: [],
    query: None,
    fragment: None,
  }
  let rest = parse_uri(uri, source)
  guard rest is [] else { raise ExtraContent(rest) }
  uri
}

///|
fn parse_uri(uri : Uri, source : StringView) -> StringView raise ParseError {
  fn parse_hier_part(source : StringView) -> StringView raise ParseError {
    match source {
      [.. "//", .. s] => return parse_authority(s, uri)
      [..] as s => {
        uri.authority = None
        return parse_path_abempty(s, uri)
      }
    }
  }

  fn parse_scheme(
    source : StringView,
    k : StringView,
  ) -> StringView raise ParseError {
    match k {
      ['a'..='z' | 'A'..='Z', .. s] =>
        scheme~: loop s {
          ['a'..='z' | 'A'..='Z' | '0'..='9' | '+' | '-' | '.', .. s] =>
            continue scheme~ s
          [':', .. k] as s => {
            uri.scheme = source.slice_until(s)
            return parse_hier_part(k)
          }
          [_, ..] as s => raise ParseError::InvalidScheme(s)
          [] => raise ParseError::MissingColon
        }
      [_, ..] as s => raise ParseError::InvalidScheme(s)
      [] => raise ParseError::Eof
    }
  }

  match source {
    ['a'..='z' | 'A'..='Z', .. s] => return parse_scheme(source, s)
    [_, ..] as s => raise ParseError::InvalidScheme(s)
    [] => raise ParseError::MissingScheme
  }
}

///|
test {
  let uri = Uri::{
    scheme: "",
    authority: None,
    path: [],
    query: None,
    fragment: None,
  }
  inspect(
    parse_uri(
      uri, "http://username:password@example.com:8443/path/to/resource?query=parameter#fragment",
    ),
    content="",
  )
  assert_eq(uri.scheme, "http")
  let authority = uri.authority.unwrap_or_error(
    Failure::Failure("Missing authority"),
  )
  assert_eq(authority.userinfo, Some("username:password"))
  assert_eq(authority.host, "example.com")
  assert_eq(authority.port, Some(8443))
  assert_eq(uri.path, ["path", "to", "resource"])
  assert_eq(uri.query, Some("query=parameter"))
  assert_eq(uri.fragment, Some("fragment"))
}

///|
test {
  let uri = Uri::{
    scheme: "",
    authority: None,
    path: [],
    query: None,
    fragment: None,
  }
  inspect(
    parse_uri(uri, "http://username:password@example.com:8443/path/to/resource"),
    content="",
  )
  assert_eq(uri.scheme, "http")
  let authority = uri.authority.unwrap_or_error(
    Failure::Failure("Missing authority"),
  )
  assert_eq(authority.userinfo, Some("username:password"))
  assert_eq(authority.host, "example.com")
  assert_eq(authority.port, Some(8443))
  assert_eq(uri.path, ["path", "to", "resource"])
  assert_eq(uri.query, None)
  assert_eq(uri.fragment, None)
}
