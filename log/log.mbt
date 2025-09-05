///|
pub(all) enum Level {
  Debug
  Info
  Warn
  Error
}

///|
pub impl ToJson for Level with to_json(self : Level) -> Json {
  match self {
    Debug => "debug"
    Info => "info"
    Warn => "warn"
    Error => "error"
  }
}

///|
enum Transport {
  File(@fs.File)
}

///|
async fn Transport::write(self : Transport, content : Json) -> Unit raise {
  match self {
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
pub async fn Transport::file(path : @string.View) -> Transport raise {
  let path = @encoding.encode(path, encoding=UTF8)
  let file = @fs.open(path, mode=WriteOnly, append=true, sync=Full)
  Transport::File(file)
}

///|
struct Logger {
  tag : String
  transport : Transport
}

///|
pub fn Logger::new(tag : String, transport : Transport) -> Logger {
  Logger::{ tag, transport }
}

///|
async fn Logger::write(self : Self, content : Json) -> Unit raise {
  self.transport.write(content)
}

///|
pub async fn Logger::error(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.write({
    "timestamp": @env.now().to_json(),
    "tag": self.tag.to_json(),
    "level": Level::Error.to_json(),
    "message": message.to_json(),
    "content": content.to_json(),
  })
}

///|
pub async fn Logger::warn(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.write({
    "timestamp": @env.now().to_json(),
    "tag": self.tag.to_json(),
    "level": Level::Warn.to_json(),
    "message": message.to_json(),
    "content": content.to_json(),
  })
}

///|
pub async fn Logger::info(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.write({
    "timestamp": @env.now(),
    "tag": self.tag.to_json(),
    "level": Level::Info.to_json(),
    "message": message,
    "content": content,
  })
}

///|
pub async fn Logger::debug(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.write({
    "timestamp": @env.now().to_json(),
    "tag": self.tag.to_json(),
    "level": Level::Debug.to_json(),
    "message": message.to_json(),
    "content": content.to_json(),
  })
}
