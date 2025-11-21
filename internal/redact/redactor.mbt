///|
struct Redactor {
  replacers : Array[Replacer]
}

///|
priv enum Replacer {
  String(String, String)
  Regexp(@regexp.Regexp, String)
  JsonPath(JsonPath, Json)
}

///|
pub fn Redactor::new() -> Redactor {
  Redactor::{ replacers: [] }
}

///|
pub fn Redactor::add_regexp(
  self : Redactor,
  pattern : @regexp.Regexp,
  replace : String,
) -> Unit {
  self.replacers.push(Replacer::Regexp(pattern, replace))
}

///|
pub fn Redactor::add_string(
  self : Redactor,
  target : String,
  replace : String,
) -> Unit {
  self.replacers.push(Replacer::String(target, replace))
}

///|
pub fn Redactor::redact_text(self : Redactor, text : String) -> String {
  let mut text = text
  for replacer in self.replacers {
    match replacer {
      String(target, replace) =>
        text = text.replace_all(old=target, new=replace)
      Regexp(pattern, replace) => {
        let replaced = StringBuilder::new()
        loop pattern.execute(text) {
          matched =>
            if matched.get(0) is Some(_) {
              replaced.write_stringview(matched.before())
              replaced.write_string(replace)
              continue pattern.execute(matched.after())
            } else {
              replaced.write_stringview(matched.before())
              break
            }
        }
        text = replaced.to_string()
      }
      JsonPath(_, _) => ()
    }
  }
  text
}

///|
pub fn Redactor::redact_json(self : Redactor, json : Json) -> Json {
  match json {
    Array(elements) =>
      elements.map(element => self.redact_json(element)) |> Json::array()
    Object(entries) => {}
  }
}

///|
priv enum JsonPathStep {
  Root
  Key(String)
  Index(Int)
  Wildcard
} derive(Eq, Hash)

///|
impl ToJson for JsonPathStep with to_json(self : JsonPathStep) -> Json {
  match self {
    Root => "$"
    Key(key) => key.to_json()
    Index(index) => index.to_json()
    Wildcard => "*"
  }
}

///|
struct JsonPath(Array[JsonPathStep]) derive(Eq, Hash)

///|
priv struct JsonPathView(ArrayView[JsonPathStep]) derive(Eq, Hash)

///|
pub impl ToJson for JsonPath with to_json(self : JsonPath) -> Json {
  self.0.to_json()
}

///|
pub fn JsonPath::parse(string : StringView) -> JsonPath raise {
  let steps = []
  let mut last_step = string
  loop string.view() {
    ['.', .. rest] as view => {
      let step = string
        .data()
        .view(
          start_offset=last_step.start_offset(),
          end_offset=view.start_offset(),
        )
      match step {
        "$" => steps.push(Root)
        "*" => steps.push(Wildcard)
        ['.', .. key] => steps.push(Key(key.to_string()))
        ['[', .. index, ']'] => steps.push(Index(@strconv.parse_int(index)))
        _ => fail("Invalid JSON path step: \{step.to_string()}")
      }
      last_step = view
      continue rest
    }
    ['[', .. rest] as view => {
      let step = string
        .data()
        .view(
          start_offset=last_step.start_offset(),
          end_offset=view.start_offset(),
        )
      match step {
        "$" => steps.push(Root)
        "*" => steps.push(Wildcard)
        ['.', .. key] => steps.push(Key(key.to_string()))
        ['[', .. index, ']'] => steps.push(Index(@strconv.parse_int(index)))
        _ => fail("Invalid JSON path step: \{step.to_string()}")
      }
      last_step = view
      continue rest
    }
    [] as view => {
      let step = string
        .data()
        .view(
          start_offset=last_step.start_offset(),
          end_offset=view.start_offset(),
        )
      match step {
        "$" => steps.push(Root)
        "*" => steps.push(Wildcard)
        ['.', .. key] => steps.push(Key(key.to_string()))
        ['[', .. index, ']'] => steps.push(Index(@strconv.parse_int(index)))
        _ => fail("Invalid JSON path step: \{step.to_string()}")
      }
      break
    }
    [_, .. rest] => continue rest
  }
  steps
}

///|
fn JsonPath::redact_json_with(
  path : JsonPath,
  json : Json,
  replace : Json,
) -> Json {
  enum JsonMatcher {
    JsonPath(JsonPath)
    JsonPathView(JsonPathView)
  } derive(Eq, Hash)
  fn redact_json(
    matchers : Set[JsonMatcher],
    json : Json,
    replace : Json,
  ) -> Unit {
    match json {
      Object(entries) => {
        for matcher in matchers {
          match matcher {
            JsonPathView(view) =>
              match (view.0, json) {
                ([Key(key)], Object(entries)) =>
                  if entries.contains(key) {
                    entries[key] = replace
                  }
                ([Key(key), .. rest] as path, Object(entries)) => {
                  let ms = matchers.copy()
                  if entries.contains(key) {
                    ms.add(JsonPathView(JsonPathView(rest)))
                  }
                }
              }
            JsonPath(path) => {}
          }
        }
      }
    }
  }

  ...
}
