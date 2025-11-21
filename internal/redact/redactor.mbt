///|
struct Redactor {
  replacers : Array[Replacer]
}

///|
priv enum Matcher {
  String(String)
  Regexp(@regexp.Regexp)
  JsonPath(JsonPath)
}

///|
priv struct Replacer {
  matcher : Matcher
  replace : String
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
  let matcher = Matcher::Regexp(pattern)
  self.replacers.push(Replacer::{ matcher, replace })
}

///|
pub fn Redactor::add_string(
  self : Redactor,
  target : String,
  replace : String,
) -> Unit {
  let matcher = Matcher::String(target)
  self.replacers.push(Replacer::{ matcher, replace })
}

///|
pub fn Redactor::redact_text(self : Redactor, text : String) -> String {
  let mut text = text
  for replacer in self.replacers {
    match replacer.matcher {
      String(target) =>
        text = text.replace_all(old=target, new=replacer.replace)
      Regexp(re) => {
        let replaced = StringBuilder::new()
        loop re.execute(text) {
          matched =>
            if matched.get(0) is Some(_) {
              replaced.write_stringview(matched.before())
              replaced.write_string(replacer.replace)
              continue re.execute(matched.after())
            } else {
              replaced.write_stringview(matched.before())
              break
            }
        }
        text = replaced.to_string()
      }
      JsonPath(_) => ()
    }
  }
  text
}

///|
priv enum JsonPathStep {
  Root
  Key(String)
  Index(Int)
  Wildcard
}

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
struct JsonPath(Array[JsonPathStep])

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
