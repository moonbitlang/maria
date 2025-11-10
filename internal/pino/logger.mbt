///|
struct Logger {
  properties : Map[String, Json]
  level : Level
  transport : Transport
}

///|
pub fn logger(
  tag : String,
  level? : Level = Info,
  transport : Transport,
) -> Logger {
  Logger::{ properties: { "tag": tag.to_json() }, level, transport }
}

///|
pub async fn Logger::close(self : Logger) -> Unit {
  self.transport.close()
}

///|
pub async fn Logger::log(
  self : Self,
  level : Level,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  if level.to_int() < self.level.to_int() {
    return
  }
  let object : Map[String, Json] = {
    "level": level.to_int().to_json(),
    "pid": @spawn.getpid().to_json(),
    "msg": message.to_json(),
  }
  try {
    object["hostname"] = @os.gethostname().to_json()
  } catch {
    _ => ()
  }
  let time_ms = @async.now()
  object["time"] = Json::number(time_ms.to_double(), repr=time_ms.to_string())
  for k, v in self.properties {
    object[k] = v
  }
  for k, v in content {
    object[k] = v
  }
  self.transport.write(object.to_json())
}

///|
pub async fn Logger::error(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Error, message, content)
}

///|
pub async fn Logger::warn(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Warn, message, content)
}

///|
pub async fn Logger::info(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Info, message, content)
}

///|
pub async fn Logger::debug(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Debug, message, content)
}

///|
pub fn Logger::child(self : Logger, properties : Map[String, Json]) -> Logger {
  let child_properties = {}
  for k, v in self.properties {
    child_properties[k] = v
  }
  for k, v in properties {
    child_properties[k] = v
  }
  Logger::{
    properties: child_properties,
    level: self.level,
    transport: self.transport,
  }
}
