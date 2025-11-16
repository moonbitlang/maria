///|
struct Url {
  mut scheme : String
  username : String
  password : String
  host : Host?
  port : UInt16?
  mut path : Path
  query : String?
  fragment : String?
}

///|
fn trim_c0_control(input : StringView) -> StringView {
  let input = loop input {
    ['\u{0000}'..='\u{001f}' | '\u{007f}', .. input] => continue input
    input => break input
  }
  let input = loop input {
    ['\u{0000}'..='\u{001f}' | '\u{007f}', .. input] => continue input
    input => break input
  }
  input
}

///|
fn Url::is_special(self : Url) -> Bool {
  match self.scheme {
    "ftp" | "file" | "http" | "https" | "ws" | "wss" => true
    _ => false
  }
}

///|
fn Url::parse_basic(
  url : Url,
  base? : Url,
  input : StringView,
) -> Url raise ValidationError {
  enum State {
    SchemeStart
    Scheme
    NoScheme
    File
    SpecialRelativeOrAuthority
    SpecialAuthoritySlashes
    PathOrAuthority
    OpaquePath
  }
  let mut state = SchemeStart
  let input = trim_c0_control(input)
  let buffer = StringBuilder::new()
  for pointer = input; !pointer.is_empty() {
    match state {
      SchemeStart =>
        match pointer {
          ['a'..='z' | 'A'..='Z' as c, .. remaining] => {
            buffer.write_char(c.to_ascii_uppercase())
            state = Scheme
            continue remaining
          }
          _ => {
            state = NoScheme
            break
          }
        }
      Scheme =>
        match pointer {
          ['a'..='z' | 'A'..='Z' | '0'..='9' | '+' | '-' | '.' as c, .. input] => {
            buffer.write_char(c.to_ascii_uppercase())
            continue input
          }
          [':', .. remaining] => {
            url.scheme = buffer.to_string()
            buffer.reset()
            if url.scheme is "file" {
              state = File
            } else if url.is_special() &&
              base is Some(base) &&
              base.scheme == url.scheme {
              guard base.is_special() else {
                abort("url.is_special() != base.is_special()")
              }
              state = SpecialRelativeOrAuthority
            } else if url.is_special() {
              state = SpecialAuthoritySlashes
            } else if remaining is ['/', .. remaining] {
              state = PathOrAuthority
              continue remaining
            } else {
              url.path = Opaque("")
              state = OpaquePath
            }
          }
          _ => {
            buffer.reset()
            state = NoScheme
            continue input
          }
        }
      NoScheme => {
        match base {
          None
          | Some({ path: Opaque(_), .. }) if !(pointer is ['#', ..]) => {
            raise MissingSchemeNonRelativeUrl
          }
          Some({ path: Opaque(_), .. } as base) if pointer is ['#', ..] => {
            url.scheme = base.scheme
          }
        }
      }
    }
  }
  ...
}
