///|
struct Logger {
  tag : String
  level : Level
  queue : @aqueue.Queue[Json]
  transport : Transport
}

///|
pub fn logger(
  tag : String,
  level? : Level = Info,
  transport : Transport,
) -> Logger {
  Logger::{ tag, level, queue: @aqueue.Queue::new(), transport }
}

///|
pub fn Logger::close(self : Logger) -> Unit {
  self.transport.close()
}

///|
pub fn Logger::log(
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
  let time_ms = @os.now_ms()
  object["time"] = Json::number(time_ms.to_double(), repr=time_ms.to_string())
  if self.tag != "" {
    object["tag"] = self.tag.to_json()
  }
  for k, v in content {
    object[k] = v
  }
  self.queue.put(object.to_json())
}

///|
pub fn Logger::error(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Error, message, content)
}

///|
pub fn Logger::warn(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Warn, message, content)
}

///|
pub fn Logger::info(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Info, message, content)
}

///|
pub fn Logger::debug(
  self : Self,
  message : StringView,
  content : Map[String, Json],
) -> Unit {
  self.log(Level::Debug, message, content)
}

///|
pub fn Logger::child(self : Logger, tag : String) -> Logger {
  Logger::{
    tag,
    level: self.level,
    queue: @aqueue.Queue::new(),
    transport: self.transport,
  }
}

///|
pub async fn Logger::start(self : Logger) -> Unit {
  loop self.queue.get() {
    json => {
      self.transport.write(json)
      continue self.queue.get()
    }
  }
}
