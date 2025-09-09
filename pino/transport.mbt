///|
enum Transport {
  Console
  File(@fs.File)
}

///|
pub suberror InvalidTransport @string.View derive(Show)

///|
pub async fn transport(transport : @string.View) -> Transport raise {
  let schema = StringBuilder::new()
  let path : @string.View = loop transport {
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
async fn Transport::write(self : Transport, content : Json) -> Unit raise {
  match self {
    Console => println(content.stringify())
    File(file) => {
      let content = content.to_json().stringify()
      let buffer = @buffer.new()
      @encoding.encode_to(content, buffer, encoding=UTF8)
      buffer.write_byte('\n')
      file.write(buffer.to_bytes())
    }
  }
}

///|
fn Transport::close(self : Transport) -> Unit {
  match self {
    Console => ()
    File(file) => file.close()
  }
}

///|
pub fn Transport::console() -> Transport {
  Transport::Console
}

///|
pub async fn Transport::file(path : @string.View) -> Transport raise {
  let path = @utf8.encode(path)
  let dir : Bytes = [..@path.dirname(path)]
  if !@fs.exists(dir) {
    @fs.mkdir(dir, permission=0o755)
  }
  let file = if @fs.exists(path) {
    @fs.open(path, mode=WriteOnly, append=true, create=0o644)
  } else {
    @fs.create(path, permission=0o644)
  }
  Transport::File(file)
}
