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
  if !@fs.exists(directory) {
    self.logger.warn("Directory '\{directory}' does not exist, skipping.", {})
    return
  }
  let dir = @fs.list_directory(directory).filter(e => e.kind
    is @fs.FileKind::Regular &&
    e.name.has_suffix(".md"))
  for rule_path in dir {
    let name = @path.stem(rule_path.name).to_string()
    self.rules[name] = Rule::parse(@fs.read_file(rule_path.path), source~)
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
fn parse_yaml_value(string : StringView) -> Json {
  let string = lexmatch string with longest {
      ("\s*" (".*" as string) "\s*") => string
      string => string
    }
  match string {
    ['"', .. string, '"'] | ['\'', .. string, '\''] =>
      Json::string(string.to_string())
    "true" => Json::boolean(true)
    "false" => Json::boolean(false)
    ['[', .. string, ']'] =>
      Json::array(string.split(",").map(s => parse_yaml_value(s)).collect())
    _ if (try? @strconv.parse_double(string)) is Ok(number) =>
      Json::number(number)
    _ => Json::string(string.to_string())
  }
}

///|
test {
  @json.inspect(
    parse_yaml_value(
      (
        #|[1, 2, 3]
      ),
    ),
    content=[1, 2, 3],
  )
  @json.inspect(
    parse_yaml_value(
      (
        #|"hello"
      ),
    ),
    content="hello",
  )
  @json.inspect(
    parse_yaml_value(
      (
        #|  true
      ),
    ),
    content=true,
  )
  @json.inspect(
    parse_yaml_value(
      (
        #|  false
      ),
    ),
    content=false,
  )
  @json.inspect(
    parse_yaml_value(
      (
        #|  123.45
      ),
    ),
    content=123.45,
  )
}

///|
fn Rule::parse(content : String, source~ : Source) -> Rule {
  enum State {
    PreFrontMatter
    FrontMatter
    PostFrontMatter
  }
  let mut state : State = PreFrontMatter
  let front_matter : Map[StringView, Json] = {}
  let builder = StringBuilder::new()
  for line in content.split("\n") {
    let line = line.to_string()
    match state {
      PreFrontMatter =>
        lexmatch line with longest {
          "\s*---\s*" => state = FrontMatter
          _ => continue
        }
      FrontMatter =>
        lexmatch line with longest {
          "\s*" => continue
          ("\s*#", _) => continue
          "\s*---\s*" => state = PostFrontMatter
          (("\s*[^:]*" as key) ":\s*", rest) => {
            let value = parse_yaml_value(rest)
            if key is ("alwaysApply" | "always_apply" | "always-apply") {
              front_matter["alwaysApply"] = value
            } else {
              front_matter[key] = value
            }
          }
          _ => continue
        }
      PostFrontMatter => {
        builder.write_string(line)
        builder.write_char('\n')
      }
    }
  }
  let description = match front_matter.get("description") {
    Some(Json::String(desc)) => Some(desc)
    _ => None
  }
  let globs = match front_matter.get("globs") {
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
  let always_apply : Bool = match front_matter.get("alwaysApply") {
    Some(True) => true
    Some(False) => false
    _ => false
  }
  Rule::{
    description,
    globs,
    always_apply,
    content: builder.to_string().trim_end(char_set=" \r\t\n").to_string(),
    source,
  }
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
    "content": "\nconsole.log(\"Hello, world!\");",
    "source": "Global",
  })
}

///|
pub fn Loader::format(self : Loader) -> String {
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
