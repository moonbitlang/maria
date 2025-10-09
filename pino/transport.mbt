///|
enum Transport {
  Console
  File(path~ : String, mut file~ : @fs.File?)
}

///|
pub suberror InvalidTransport StringView derive(Show)

///|
pub fn transport(transport : StringView) -> Transport raise {
  let schema = StringBuilder::new()
  let path : StringView = loop transport {
    [] as path => break path
    [':', .. rest] => break rest
    [c, .. rest] => {
      schema.write_char(c)
      continue rest
    }
  }
  match schema.to_string() {
    "console" => {
      if path != "" {
        raise InvalidTransport(transport)
      }
      Transport::Console
    }
    "file" => Transport::file(path)
    schema => raise InvalidTransport(schema)
  }
}

///|
async fn Transport::write(self : Transport, content : Json) -> Unit {
  match self {
    Console => println(content.stringify())
    File(path~, file~) as transport => {
      let file = match file {
        Some(file) => file
        None => {
          let dir : String = [..@path.dirname(path)]
          if !@fs.exists(dir) {
            @fs.mkdir(dir, permission=0o755)
          }
          let file = if @fs.exists(path) {
            @fs.open(path, mode=WriteOnly, append=true, create=0o644)
          } else {
            @fs.create(path, permission=0o644)
          }
          transport.file = Some(file)
          file
        }
      }
      let content = content.to_json().stringify()
      let buffer = @buffer.new()
      buffer.write_bytes(@encoding/utf8.encode(content))
      buffer.write_byte('\n')
      file.write(buffer.to_bytes())
    }
  }
}

///|
fn Transport::close(self : Transport) -> Unit {
  match self {
    Console => ()
    File(file=Some(file), ..) => file.close()
    File(..) => ()
  }
}

///|
pub fn Transport::console() -> Transport {
  Transport::Console
}

///|
pub fn Transport::file(path : StringView) -> Transport {
  Transport::File(path=path.to_string(), file=None)
}
