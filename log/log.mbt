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
fn Transport::close(self : Transport) -> Unit {
  match self {
    File(file) => file.close()
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
pub fn Logger::new(tag? : String = "", transport : Transport) -> Logger {
  Logger::{ tag, transport }
}

///|
pub fn Logger::close(self : Logger) -> Unit {
  self.transport.close()
}

///|
pub async fn Logger::log(
  self : Self,
  level : Level,
  message : @string.View,
  content : Json,
) -> Unit raise {
  let object : Map[String, Json] = {
    "timestamp": @env.now().to_json(),
    "tag": self.tag.to_json(),
    "level": level.to_json(),
    "message": message.to_json(),
    "content": content.to_json(),
  }
  if self.tag != "" {
    object["tag"] = self.tag.to_json()
  }
  self.transport.write(object.to_json())
}

///|
pub async fn Logger::error(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.log(Level::Error, message, content.to_json())
}

///|
pub async fn Logger::warn(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.log(Level::Warn, message, content.to_json())
}

///|
pub async fn Logger::info(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.log(Level::Info, message, content.to_json())
}

///|
pub async fn Logger::debug(
  self : Self,
  message : @string.View,
  content : Json,
) -> Unit raise {
  self.log(Level::Debug, message, content.to_json())
}
