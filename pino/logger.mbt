///|
struct Logger {
  tag : String
  level : Level
  transport : Transport
}

///|
pub fn logger(
  tag? : String = "",
  level? : Level = Info,
  transport : Transport,
) -> Logger {
  Logger::{ tag, level, transport }
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
  content : Map[String, Json],
) -> Unit raise {
  if self.level.to_int() < level.to_int() {
    return
  }
  let time = @uv.gettimeofday()
  let time_ms = time.sec() * 1000 + time.usec().to_int64() / 1000
  let object : Map[String, Json] = {
    "level": level.to_int().to_json(),
    "time": Json::number(time_ms.to_double(), repr=time_ms.to_string()),
    "pid": @uv.os_getpid().to_json(),
    "hostname": @encoding.decode(@uv.os_gethostname(), encoding=UTF8).to_json(),
    "msg": message.to_json(),
  }
  if self.tag != "" {
    object["tag"] = self.tag.to_json()
  }
  for k, v in content {
    object[k] = v
  }
  self.transport.write(object.to_json())
}

///|
pub async fn Logger::error(
  self : Self,
  message : @string.View,
  content : Map[String, Json],
) -> Unit raise {
  self.log(Level::Error, message, content)
}

///|
pub async fn Logger::warn(
  self : Self,
  message : @string.View,
  content : Map[String, Json],
) -> Unit raise {
  self.log(Level::Warn, message, content)
}

///|
pub async fn Logger::info(
  self : Self,
  message : @string.View,
  content : Map[String, Json],
) -> Unit raise {
  self.log(Level::Info, message, content)
}

///|
pub async fn Logger::debug(
  self : Self,
  message : @string.View,
  content : Map[String, Json],
) -> Unit raise {
  self.log(Level::Debug, message, content)
}

///|
pub fn Logger::child(self : Logger, tag? : String = self.tag) -> Logger {
  Logger::{ tag, level: self.level, transport: self.transport }
}
