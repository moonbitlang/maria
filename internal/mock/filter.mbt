///|
/// A keyword-based masker that swaps sensitive strings for deterministic
/// `(mock:<key>)` placeholders inside test output.
///
/// Filter is used by the mock context to scrub host-specific details (paths,
/// environment variables, secrets) from snapshots and logs without losing
/// enough information to understand what was being recorded.
struct Filter {
  keywords : Array[(String, String)]
}

///|
/// Creates an empty filter with no registered keywords.
fn Filter::new() -> Filter {
  Filter::{ keywords: [] }
}

///|
/// Registers a literal value to be replaced with a `(mock:<key>)` placeholder.
///
/// Replacements run in insertion order. If an earlier keyword replaces text that
/// a later keyword would have matched, the later replacement will not occur.
fn Filter::add(self : Filter, key : String, value : String) -> Unit {
  self.keywords.push((key, value))
}

///|
/// Internal hook that lets the filter operate on multiple value types.
priv trait Filterable {
  filter(self : Filter, value : Self) -> Self
}

///|
/// Masks a string using all registered keywords.
fn Filter::apply_string(self : Filter, value : String) -> String {
  Filterable::filter(self, value)
}

///|
/// Recursively masks strings and object keys inside a JSON value.
fn Filter::apply_json(self : Filter, value : Json) -> Json {
  Filterable::filter(self, value)
}

///|
/// Applies keyword replacements to plain strings, swapping every literal match
/// with the `(mock:<key>)` token.
impl Filterable for String with filter(self : Filter, content : String) -> String {
  let mut content = content
  for keyword in self.keywords {
    let (key, value) = keyword
    content = content.replace_all(old=value, new="(mock:\{key})")
  }
  content
}

///|
/// Walks through JSON structures, masking both string values and object keys
/// using the same keyword replacements. Non-string JSON values are passed
/// through untouched.
impl Filterable for Json with filter(self : Filter, value : Json) -> Json {
  match value {
    String(string) => Json::string(Filterable::filter(self, string))
    Array(array) => Json::array(array.map(e => Filterable::filter(self, e)))
    Object(old_object) => {
      let new_object = {}
      for k, v in old_object {
        new_object[Filterable::filter(self, k)] = Filterable::filter(self, v)
      }
      Json::object(new_object)
    }
    _ => value
  }
}
