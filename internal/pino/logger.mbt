///|
struct Logger {
  properties : Map[String, Json]
  level : Level
  transport : Transport
}

///|
/// Creates a new logger instance.
///
/// # Parameters
/// - `tag`: A string identifier for the logger, typically representing the component or module
/// - `level`: Optional logging level threshold (default: Info). Messages below this level will be filtered
/// - `transport`: The transport mechanism for outputting log messages
///
/// # Returns
/// A configured Logger instance
///
/// # Example
/// ```moonbit nocheck
/// let _log = logger("my-app", level=Debug, Transport::console())
/// ```
pub fn logger(
  tag : String,
  level? : Level = Info,
  transport : Transport,
) -> Logger {
  Logger::{ properties: { "tag": tag }, level, transport }
}

///|
/// Closes the logger and releases any resources held by the transport.
///
/// This method should be called when the logger is no longer needed to ensure
/// proper cleanup of resources (e.g., closing file handles).
pub fn Logger::close(self : Logger) -> Unit {
  self.transport.close()
}

///|
/// Logs a message at the specified level with additional context.
///
/// This is the core logging method. All level-specific methods (error, warn, info, debug)
/// delegate to this function.
///
/// # Parameters
/// - `level`: The severity level of the log message
/// - `message`: The main log message
/// - `content`: Additional key-value pairs to include in the log entry
///
/// # Behavior
/// - Messages below the logger's configured level are filtered out
/// - Automatically adds timestamp, process ID, hostname, and configured properties
/// - Merges logger properties and content properties into the final log entry
pub async fn Logger::log(
  self : Self,
  level : Level,
  message : StringView,
  data? : Map[String, Json],
) -> Unit {
  if level < self.level {
    return
  }
  let object : Map[String, Json] = {
    "level": level,
    "pid": @spawn.getpid(),
    "msg": message,
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
  if data is Some(data) {
    for k, v in data {
      object[k] = v
    }
  }
  self.transport.write(object.to_json())
}

///|
/// Logs an error-level message.
///
/// # Parameters
/// - `message`: The error message to log
/// - `content`: Additional context to include with the error
pub async fn Logger::error(
  self : Self,
  message : StringView,
  data? : Map[String, Json],
) -> Unit {
  self.log(Error, message, data?)
}

///|
/// Logs a warning-level message.
///
/// # Parameters
/// - `message`: The warning message to log
/// - `content`: Additional context to include with the warning
pub async fn Logger::warn(
  self : Self,
  message : StringView,
  data? : Map[String, Json],
) -> Unit {
  self.log(Warn, message, data?)
}

///|
/// Logs an info-level message.
///
/// # Parameters
/// - `message`: The informational message to log
/// - `content`: Additional context to include with the message
pub async fn Logger::info(
  self : Self,
  message : StringView,
  data? : Map[String, Json],
) -> Unit {
  self.log(Info, message, data?)
}

///|
/// Logs a debug-level message.
///
/// # Parameters
/// - `message`: The debug message to log
/// - `content`: Additional context to include with the debug information
pub async fn Logger::debug(
  self : Self,
  message : StringView,
  data? : Map[String, Json],
) -> Unit {
  self.log(Debug, message, data?)
}

///|
/// Creates a child logger that inherits properties from the parent logger.
///
/// Child loggers share the same transport and level as their parent but can have
/// additional properties merged into their log entries.
///
/// # Parameters
/// - `properties`: Additional key-value pairs to include in all log entries from the child logger
///
/// # Returns
/// A new Logger instance with merged properties
///
/// # Example
/// ```moonbit nocheck
/// let parent = logger("app", Transport::console())
///
/// let _child = parent.child({ "module": "auth" })
/// // All logs from child will include both "tag": "app" and "module": "auth"
/// ```
pub fn Logger::child(self : Logger, properties : Map[String, Json]) -> Logger {
  let child_properties = self.properties.copy()
  for k, v in properties {
    child_properties[k] = v
  }
  { ..self, properties: child_properties }
}
