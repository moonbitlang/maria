///|
priv struct Entry {
  level : Level
  pid : Int
  hostname : String?
  time : Int64
  msg : String
  data : Map[String, Json]
}

///|
impl ToJson for Entry with to_json(self : Entry) -> Json {
  let object : Map[String, Json] = {
    "level": self.level,
    "pid": self.pid,
    "msg": self.msg,
  }
  if self.hostname is Some(hostname) {
    object["hostname"] = hostname.to_json()
  }
  object["time"] = Json::number(
    self.time.to_double(),
    repr=self.time.to_string(),
  )
  for k, v in self.data {
    object[k] = v
  }
  Json::object(object)
}

///|
struct Transport {
  write : async (Entry) -> Unit
  close : (() -> Unit)?
}

///|
fn Transport::new(
  write : async (Entry) -> Unit,
  close? : () -> Unit,
) -> Transport {
  Transport::{ write, close }
}

///|
suberror InvalidTransport StringView derive(Show)

///|
/// Parses a transport string and creates the corresponding Transport instance.
///
/// Parameters:
///
/// - `transport`: A string in the format "scheme:path" specifying the transport type
///
/// Supported Schemes:
///
/// - "console:" - Outputs to standard output (path must be empty)
/// - "file:path" - Outputs to a file at the specified path
///
/// Returns A configured Transport instance
///
/// Raises `InvalidTransport` if the scheme is unknown or the format is invalid
///
/// Example:
///
/// ```moonbit
/// let _ = transport("console:")
/// let _ = transport("file:/var/log/app.log")
/// ```
pub fn Transport::parse(transport : StringView) -> Transport raise InvalidTransport {
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
      Transport::console()
    }
    "file" => Transport::file(path)
    schema => raise InvalidTransport(schema)
  }
}

///|
async fn mkdir(path : String) -> Unit {
  let dirs = []
  for dir = path.view() {
    let dir = dir.to_string()
    if dir == "." || dir == "" || @fs.exists(dir) {
      break
    }
    dirs.push(dir)
    continue @path.dirname(dir)
  }
  for i in 0..<dirs.length() {
    let dir = dirs[dirs.length() - 1 - i]
    @fs.mkdir(dir, permission=0o755) catch {
      @os_error.OSError(errno, ..) if errno == @errno.eexist => ()
      error => raise error
    }
  }
}

///|
fn Transport::close(self : Transport) -> Unit {
  match self.close {
    Some(close) => close()
    None => ()
  }
}

///|
/// Creates a console transport that outputs to standard output.
///
/// Log messages are written to stdout as JSON strings, one per line.
///
/// Returns A Transport configured for console output
pub fn Transport::console() -> Transport {
  Transport::new(entry => println(
    if entry.data.is_empty() {
      "[\{entry.level}] \{entry.msg}"
    } else {
      "[\{entry.level}] \{entry.msg} \{entry.data.to_json().stringify(indent=2)}"
    },
  ))
}

///|
/// Creates a file transport that writes logs to the specified file.
///
/// Parameters:
///
/// - `path`: The file path where logs will be written
///
/// Returns A Transport configured for file output
pub fn Transport::file(path : StringView) -> Transport {
  let mut file = None
  Transport::new(
    entry => {
      let file = match file {
        Some(file) => file
        None => {
          let dir : String = [..@path.dirname(path)]
          if !@fs.exists(dir) {
            mkdir(dir)
          }
          let f = if @fs.exists(path) {
            @fs.open(path, mode=WriteOnly, append=true, create=0o644)
          } else {
            @fs.create(path, permission=0o644)
          }
          file = Some(f)
          f
        }
      }
      let content = entry.to_json().stringify()
      let buffer = @buffer.new()
      buffer.write_bytes(@encoding/utf8.encode(content))
      buffer.write_byte('\n')
      file.write(buffer.to_bytes())
    },
    close=() => if file is Some(f) { f.close() },
  )
}

///|
/// Creates a sink transport that discards all log messages.
///
/// Useful for testing or when logging needs to be disabled without
/// changing the logger configuration.
///
/// Returns A Transport that silently discards all output
pub fn Transport::sink() -> Transport {
  Transport::new(_ => ())
}

///|
/// Creates a channel transport that sends log entries to a queue.
///
/// Parameters:
///
/// - `queue`: An async queue that will receive Json log objects
///
/// Returns A Transport that sends logs to the specified queue
///
/// # Note
/// This method is deprecated; the alias "chan" is provided for backward compatibility
#alias(chan, deprecated)
pub fn Transport::channel(queue : @aqueue.Queue[Json]) -> Transport {
  Transport::new(entry => queue.put(entry.to_json()))
}

///|
/// Creates a callback transport that invokes a custom function for each log entry.
///
/// Parameters:
///
/// - `callback`: A function that will be called with each Json log object
///
/// Returns A Transport that delegates log handling to the provided callback
///
/// # Use Cases
/// - Custom log processing or formatting
/// - Integration with external logging systems
/// - Testing and log capture
pub fn Transport::callback(callback : (Json) -> Unit) -> Transport {
  Transport::new(entry => callback(entry.to_json()))
}
