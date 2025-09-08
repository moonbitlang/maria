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
let uv : Result[@uv.Loop, @uv.Errno] = try? @uv.Loop::new()

///|
pub async fn Transport::file(path : @string.View) -> Transport raise {
  let path = @encoding.encode(path, encoding=UTF8)
  if @uv.os_uname().sysname() == "Windows_NT" {
    if @path.windows(path).parent() is Some(dir) {
      let dir = dir.to_bytes()
      if !@fs.exists(dir) {
        uv.unwrap_or_error().fs_mkdir_sync(dir, 0o755)
      }
    }
  } else if @path.posix(path).parent() is Some(dir) {
    let dir = dir.to_bytes()
    if !@fs.exists(dir) {
      uv.unwrap_or_error().fs_mkdir_sync(dir, 0o755)
    }
  }
  let file = if @fs.exists(path) {
    @fs.open(path, mode=WriteOnly, append=true, create=0o644)
  } else {
    @fs.create(path, permission=0o644)
  }
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
pub async fn[T : ToJson] Logger::error(
  self : Self,
  message : @string.View,
  content : T,
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
pub async fn[T : ToJson] Logger::warn(
  self : Self,
  message : @string.View,
  content : T,
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
pub async fn[T : ToJson] Logger::info(
  self : Self,
  message : @string.View,
  content : T,
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
pub async fn[T : ToJson] Logger::debug(
  self : Self,
  message : @string.View,
  content : T,
) -> Unit raise {
  self.write({
    "timestamp": @env.now().to_json(),
    "tag": self.tag.to_json(),
    "level": Level::Debug.to_json(),
    "message": message.to_json(),
    "content": content.to_json(),
  })
}
