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
  // here we use lexmatch for full match semantics
  // so we not need non-greedy match semantics, such `.*?`
  lexmatch content with longest {
    /// ignore pre-frontmatter
    (
      (".+" as _pre_front_matter)
      (("\n---\n" (".*" as _yaml_value) "\n---\n") as front_matter)
      (".*" as text)
      ("\s*" as _trim_space)
    ) => (front_matter, text)
    // without pre-frontmatter
    (
      (("---\n" (".*" as _yaml_value) "\n---\n") as front_matter)
      (".*" as text)
      ("\s*" as _trim_space)
    ) => (front_matter, text)
    _ => ("", "")
  }
}

///|
pub fn parse(content : String) -> Document {
  let (front_matter, text) = tokenize_markdown_with_yaml_front_matter(content)
  if front_matter.is_empty() {
    Document::{ meta: {}, text: text.to_string() }
  } else {
    let yaml_value = try! Yaml::load_from_string(front_matter.to_string())[0]
    guard yaml_value.to_json() is Object(meta) else {
      abort("assume yaml value must be Map")
    }
    let text = text.to_string()
    Document::{ meta, text }
  }
}
