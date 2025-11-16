///|
struct Url {
  mut scheme : String
  mut username : String
  mut password : String
  mut host : Host?
  mut port : UInt16?
  mut path : Path
  mut query : String?
  mut fragment : String?
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
fn Url::is_special(url : Url) -> Bool {
  is_special_scheme(url.scheme)
}

///|
fn is_special_scheme(scheme : StringView) -> Bool {
  match scheme {
    "ftp" | "file" | "http" | "https" | "ws" | "wss" => true
    _ => false
  }
}

///|
priv enum State {
  SchemeStart
  Scheme
  NoScheme
  File
  Relative
  RelativeSlash
  SpecialRelativeOrAuthority
  SpecialAuthorityIgnoreSlashes
  SpecialAuthoritySlashes
  PathOrAuthority
  Authority
  Host
  Path
  OpaquePath
  Query
  Fragment
}

///|
priv struct StringPointer {
  input : StringView
  mut pointer : Int
}

///|
fn StringPointer::new(input : StringView) -> StringPointer {
  StringPointer::{ input, pointer: input.start_offset() }
}

///|
fn StringPointer::view(self : StringPointer) -> StringView {
  self.input.data().view(start_offset=self.pointer)
}

///|
fn StringPointer::next(self : StringPointer) -> StringView {
  match self.view() {
    [] as view => view
    [_, .. rest] => {
      self.pointer = rest.start_offset()
      rest
    }
  }
}

///|
fn StringPointer::increase(self : StringPointer) -> Unit {
  match self.view() {
    [] => ()
    [_, .. rest] => self.pointer = rest.start_offset()
  }
}

///|
fn StringPointer::decrease(self : StringPointer) -> Unit {

}

///|
fn StringPointer::start_over(self : StringPointer) -> Unit {
  self.pointer = self.input.start_offset()
}

///|
fn Url::parse_basic(
  url : Url,
  base? : Url,
  input : StringView,
  validation_errors? : Array[ValidationError] = [],
) -> Url? {
  let mut state : State = SchemeStart
  let buffer : StringBuilder = StringBuilder::new()
  let mut at_sign_seen : Bool = false
  let mut inside_brackets : Bool = false
  let mut password_token_seen : Bool = false
  let input = trim_c0_control(input)
  let pointer = StringPointer::new(input)
  for view = pointer.view(); view is [c, .. remaining]; view = pointer.next() {
    match state {
      SchemeStart =>
        if c.is_ascii_alphabetic() {
          buffer.write_char(c.to_ascii_uppercase())
          state = Scheme
        } else {
          state = NoScheme
          pointer.decrease()
        }
      Scheme =>
        match c {
          'a'..='z' | 'A'..='Z' | '0'..='9' | '+' | '-' | '.' =>
            buffer.write_char(c.to_ascii_uppercase())
          ':' => {
            url.scheme = buffer.to_string()
            buffer.reset()
            if url.scheme is "file" {
              if remaining.has_prefix("//") {
                validation_errors.push(SpecialSchemeMissingFollowingSolidus)
              }
              state = File
            } else if is_special_scheme(url.scheme) &&
              base is Some(base) &&
              base.scheme == url.scheme {
              guard is_special_scheme(base.scheme) else {
                abort("is_special_scheme(base.scheme) must be true")
              }
              state = SpecialRelativeOrAuthority
            } else if is_special_scheme(url.scheme) {
              state = SpecialAuthoritySlashes
            } else if remaining is ['/', ..] {
              state = PathOrAuthority
              pointer.increase()
            } else {
              url.path = Opaque("")
              state = OpaquePath
            }
          }
          _ => {
            buffer.reset()
            state = NoScheme
            pointer.start_over()
            continue pointer.view()
          }
        }
      NoScheme =>
        match base {
          None | Some({ path: Opaque(_), .. }) if !(c is '#') => {
            validation_errors.push(MissingSchemeNonRelativeUrl)
            return None
          }
          Some({ path: Opaque(_), .. } as base) if c is '#' => {
            url.scheme = base.scheme
            url.path = base.path
            url.query = base.query
            url.fragment = Some("")
            state = Fragment
          }
          Some({ scheme, .. }) if scheme != "file" => {
            state = Relative
            pointer.decrease()
          }
          _ => {
            state = File
            pointer.decrease()
          }
        }
      SpecialRelativeOrAuthority =>
        if c is '/' && remaining.has_prefix("/") {
          state = SpecialAuthorityIgnoreSlashes
          pointer.increase()
        } else {
          validation_errors.push(SpecialSchemeMissingFollowingSolidus)
          state = Relative
          pointer.decrease()
        }
      PathOrAuthority =>
        if c is '/' {
          state = Authority
        } else {
          state = Path
          pointer.decrease()
        }
      Relative => {
        guard base is Some(base) else {
          abort("base must be Some(base) in Relative state")
        }
        guard base.scheme != "file" else {
          abort("base.scheme must not be \"file\" in Relative state")
        }
        url.scheme = base.scheme
        if c is '/' {
          state = RelativeSlash
        } else if url.is_special() && c is '\\' {
          validation_errors.push(InvalidReverseSolidus)
          state = RelativeSlash
        } else {
          url.username = base.username
          url.password = base.password
          url.host = base.host
          url.port = base.port
          url.path = base.path
          url.query = base.query
          if c is '?' {
            url.query = Some("")
            state = Query
          } else if c is '#' {
            url.fragment = Some("")
            state = Fragment
          } else {
            url.query = None
            url.path.shorten()
            state = Path
            pointer.decrease()
          }
        }
      }
      RelativeSlash => {
        guard base is Some(base) else {
          abort("base must be Some(base) in RelativeSlash state")
        }
        if url.is_special() && c is ('/' | '\\') {
          if c is '/' {
            validation_errors.push(InvalidReverseSolidus)
          }
          state = SpecialAuthorityIgnoreSlashes
        } else if c is '/' {
          state = Authority
        } else {
          url.username = base.username
          url.password = base.password
          url.host = base.host
          url.port = base.port
          state = Path
          pointer.decrease()
        }
      }
      SpecialAuthoritySlashes =>
        if c is '/' && remaining.has_prefix("/") {
          state = SpecialAuthorityIgnoreSlashes
          pointer.increase()
        } else {
          validation_errors.push(SpecialSchemeMissingFollowingSolidus)
          state = SpecialAuthorityIgnoreSlashes
          pointer.decrease()
        }
      SpecialAuthorityIgnoreSlashes =>
        if !(c is ('/' | '\\')) {
          state = Authority
          pointer.decrease()
        } else {
          validation_errors.push(SpecialSchemeMissingFollowingSolidus)
        }
      Authority =>
        if c is '@' {
          validation_errors.push(InvalidCredentials)
          if at_sign_seen {
            let prepend = "%40\{buffer.to_string()}"
            buffer.reset()
            buffer.write_string(prepend)
          }
          at_sign_seen = true
          for code_point in buffer.to_string() {
            if code_point is ':' && password_token_seen {
              password_token_seen = true
              continue
            }
            let encoded_code_points = utf8_percent_encode(
              [code_point],
              userinfo_percent_encode_set,
            )
            if password_token_seen {
              url.password = "\{url.password}\{encoded_code_points}"
            } else {
              url.username = "\{url.username}\{encoded_code_points}"
            }
          }
          buffer.reset()
        } else if c is ('/' | '?' | '#') || (url.is_special() && c is '\\') {
          if at_sign_seen && buffer.is_empty() {
            validation_errors.push(HostMissing)
            return None
          }
          for _ in buffer.to_string() {
            pointer.decrease()
          }
          pointer.decrease()
          buffer.reset()
          state = Host
        } else {
          buffer.write_char(c)
        }
      Host => {
        if c is ':' && inside_brackets {
          if buffer.is_empty() {
            validation_errors.push(HostMissing)
            return None
          }
          ...
        }
      }
    }
  }
  ...
}
