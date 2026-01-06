///|
using @yaml {type Yaml}

///|
pub struct Document {
  meta : Map[String, Json]
  text : String
}

///|
fn tokenize_markdown_with_yaml_front_matter(
  content : StringView,
) -> (StringView, StringView) {
  let lines = content.split("\n").collect()
  let mut open_index : Int? = None
  let mut close_index : Int? = None
  for i = 0; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line == "---" {
      if open_index is None {
        open_index = Some(i)
        continue
      }
      close_index = Some(i)
      break
    }
  }
  match (open_index, close_index) {
    (Some(open), Some(close)) if close > open => {
      let front_matter = lines[open:close + 1].join("\n")
      let rest = if close + 1 < lines.length() {
        lines[close + 1:].join("\n")
      } else {
        ""
      }
      (front_matter[:], rest[:])
    }
    _ => ("", "")
  }
}

///|
pub fn parse(content : String) -> Document raise @yaml.YamlError {
  let (front_matter, text) = tokenize_markdown_with_yaml_front_matter(content)
  if front_matter.is_empty() {
    Document::{ meta: {}, text: text.to_string() }
  } else {
    let yaml_value = Yaml::load_from_string(front_matter.to_string())[0]
    guard yaml_value.to_json() is Object(meta) else {
      abort("assume yaml value must be Map")
    }
    let text = text.to_string()
    Document::{ meta, text }
  }
}
