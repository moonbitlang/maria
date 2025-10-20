///|
pub struct Document {
  meta : Map[String, Json]
  text : String
}

///|
pub fn parse(content : String) -> Document {
  enum State {
    PreFrontMatter
    FrontMatter
    PostFrontMatter
  }
  let mut state : State = PreFrontMatter
  let meta : Map[String, Json] = {}
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
            let value = @yaml.parse(rest)
            meta[key.to_string()] = value
          }
          _ => continue
        }
      PostFrontMatter => {
        builder.write_string(line)
        builder.write_char('\n')
      }
    }
  }
  Document::{
    meta,
    text: builder.to_string().trim_end(char_set=" \r\t\n").to_string(),
  }
}
