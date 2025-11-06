///|
struct Redactor {
  replacers : Array[Replacer]
}

///|
pub fn Redactor::new() -> Redactor {
  { replacers: [] }
}

///|
pub fn Redactor::add_string(
  self : Redactor,
  matches : String,
  replace : String,
) -> Unit {
  self.replacers.push(Replacer::{ matcher: String(matches), replace })
}

///|
pub fn Redactor::add_regexp(
  self : Redactor,
  pattern : @regexp.Regexp,
  replace : String,
) -> Unit {
  self.replacers.push(Replacer::{ matcher: Regexp(pattern), replace })
}

///|
pub fn Redactor::add_json_path(
  self : Redactor,
  path : JsonPath,
  replace : String,
) -> Unit {
  self.replacers.push(Replacer::{ matcher: JsonPath(path), replace })
}

///|
pub fn Redactor::redact_string(self : Redactor, content : String) -> String {
  let mut result = content
  for replacer in self.replacers {
    let { matcher, replace } = replacer
    match matcher {
      String(s) => result = result.replace_all(old=s, new=replace)
      Regexp(r) => {
        let replaced = StringBuilder::new()
        loop r.execute(content) {
          matched =>
            if matched.get(0) is Some(capture) {
              replaced.write_stringview(matched.before())
              replaced.write_stringview(replace)
              continue r.execute(matched.after())
            } else {
              replaced.write_stringview(matched.before())
            }
        }
        result = replaced.to_string()
      }
      JsonPath(_) => continue
    }
  }
  result
}

///|
fn deriv(path : JsonPath, json : Json) -> JsonPath {
  match (path, json) {
    (Nil, _) => Nil
    (Eps, _) => Nil
    (Key(key, path), Object(object)) => {
      if object.get(key) is Some(value) {
        deriv(path, value)
      } else {
      }
    }
  }
}

///|
pub fn Redactor::redact_json(self : Redactor, content : Json) -> Json {
  let mut result = content
  for replacer in self.replacers {
    let { matcher, replace } = replacer
    match matcher {
      JsonPath(path) => {}
      _ => continue
    }
  }
  result
}

///|
priv struct Replacer {
  matcher : Matcher
  replace : String
}

///|
pub enum JsonPath {
  Eps
  Nil
  Key(String, JsonPath)
  Idx(Int, JsonPath)
  Alt(JsonPath, JsonPath)
}

///|
priv enum Matcher {
  String(String)
  Regexp(@regexp.Regexp)
  JsonPath(JsonPath)
}
