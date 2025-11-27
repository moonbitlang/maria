///|
struct Loader {
  logger : @pino.Logger
  cwd : String
  rules : Map[String, Rule]
}

///|
pub fn Loader::new(cwd : String, logger~ : @pino.Logger) -> Loader {
  return Loader::{ cwd, logger, rules: {} }
}

///|
async fn Loader::load_rules_from_directory(
  self : Loader,
  directory : String,
  source~ : Source,
) -> Unit {
  if !@fsx.exists(directory) {
    self.logger.warn("Directory '\{directory}' does not exist, skipping.")
    return
  }
  let dir = @fsx.list_directory(directory).filter(e => e.kind
    is @fsx.FileKind::Regular &&
    e.name.has_suffix(".md"))
  for rule_path in dir {
    let name = @path.stem(rule_path.name).to_string()
    self.rules[name] = Rule::parse(@fsx.read_file(rule_path.path), source~)
  }
}

///|
pub async fn Loader::load(self : Loader) -> Unit {
  let global_path = @os.home()
    |> @path.join(".moonagent")
    |> @path.join("rules")
  self.load_rules_from_directory(global_path, source=Global)
  let local_path = self.cwd |> @path.join(".moonagent") |> @path.join("rules")
  self.load_rules_from_directory(local_path, source=Local)
}

///|
pub fn Loader::apply(self : Loader, messages : Array[@ai.Message]) -> Unit {
  if self.rules.is_empty() {
    return
  }
  let usr_msg = @ai.user_message(content=self.format())
  let ins_pos : ArrayView[@ai.Message] = loop messages[:] {
    [System(_), .. rest] => continue rest
    msgs => break msgs
  }
  messages.insert(ins_pos.start_offset(), usr_msg)
}

///|
pub enum Source {
  Global
  Local
} derive(Show, ToJson)

///|
pub struct Rule {
  description : String?
  globs : Array[String]
  always_apply : Bool
  content : String
  source : Source
} derive(Show, ToJson)

///|
fn Rule::parse(content : String, source~ : Source) -> Rule {
  let doc = @yamd.parse(content)
  let description = match doc.meta.get("description") {
    Some(Json::String(desc)) => Some(desc)
    _ => None
  }
  let globs = match doc.meta.get("globs") {
    Some(Json::Array(arr)) =>
      arr
      .iter()
      .filter_map(v => match v {
        Json::String(s) => Some(s)
        _ => None
      })
      .collect()
    _ => []
  }
  let always_apply : Bool = match doc.meta.get("alwaysApply") {
    Some(True) => true
    Some(False) => false
    _ => false
  }
  Rule::{ description, globs, always_apply, content: doc.text, source }
}

///|
test "Rule::parse" {
  let content =
    #|---
    #|description: "This is a test rule"
    #|globs: ["**/*.js", "**/*.ts"]
    #|alwaysApply: true
    #|---
    #|
    #|console.log("Hello, world!");
    #|
  let rule = Rule::parse(content.to_string(), source=Global)
  @json.inspect(rule, content={
    "description": "This is a test rule",
    "globs": ["**/*.js", "**/*.ts"],
    "always_apply": true,
    "content": "\nconsole.log(\"Hello, world!\");\n",
    "source": "Global",
  })
}

///|
test "Rule::parse/no-front-matter" {
  let content =
    #|# No front matter
  let rule = Rule::parse(content, source=Local)
  @json.inspect(rule, content={
    "globs": [],
    "always_apply": false,
    "content": "",
    "source": "Local",
  })
}

///|
fn Loader::format(self : Loader) -> String {
  let always_applied = []
  let conditional = []
  for name, rule in self.rules {
    if rule.always_apply {
      always_applied.push((name, rule))
    } else {
      conditional.push((name, rule))
    }
  }
  let content = StringBuilder::new()
  content.write_string(
    (
      $|# Project Rules
      $|
      $|Loaded \{self.rules.length()} rules from .moonagent/rules directory:
      $|
    ),
  )
  for rule in always_applied {
    let (name, rule) = rule
    let description = match rule.description {
      Some(desc) => desc
      None => "No description"
    }
    content.write_string(
      (
        $|
        $|## \{name}
        $|
        $|\{description}
        $|
        $|- **Always Apply**: \{rule.always_apply}
        $|
      ),
    )
    if rule.globs.length() > 0 {
      let globs = rule.globs.join(", ")
      content.write_string(
        (
          $|- **Globs**: [\{globs}]
          $|
        ),
      )
    }
    content.write_string(
      (
        $|- **Description**: \{description}
        $|
        $|\{rule.content}
        $|
      ),
    )
  }
  for rule in conditional {
    let (name, rule) = rule
    let description = match rule.description {
      Some(desc) => desc
      None => "No description"
    }
    content.write_string(
      (
        $|
        $|## \{name}
        $|
        $|\{description}
        $|
        $|- **Always Apply**: \{rule.always_apply}
        $|
      ),
    )
    if rule.globs.length() > 0 {
      let globs = rule.globs.join(", ")
      content.write_string(
        (
          $|- **Globs**: [\{globs}]
          $|
        ),
      )
    }
    content.write_string(
      (
        $|- **Description**: \{description}
        $|
      ),
    )
  }
  content.to_string()
}
