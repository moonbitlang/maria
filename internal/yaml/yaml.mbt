///|
pub fn parse(string : StringView) -> Json {
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
      Json::array(string.split(",").map(s => parse(s)).collect())
    _ if (try? @strconv.parse_double(string)) is Ok(number) =>
      Json::number(number)
    _ => Json::string(string.to_string())
  }
}
