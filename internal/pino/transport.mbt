///|
enum Transport {
  Console
  File(path~ : String, mut file~ : @fs.File?)
  Channel(@aqueue.Queue[Json])
  Sink
  Callback((Json) -> Unit)
}

///|
priv suberror InvalidTransport StringView derive(Show)

///|
/// Parses a transport string and creates the corresponding Transport instance.
///
/// # Parameters
/// - `transport`: A string in the format "scheme:path" specifying the transport type
///
/// # Supported Schemes
/// - "console:" - Outputs to standard output (path must be empty)
/// - "file:path" - Outputs to a file at the specified path
///
/// # Returns
/// A configured Transport instance
///
/// # Raises
/// - `InvalidTransport` if the scheme is unknown or the format is invalid
///
/// # Example
/// ```moonbit
/// let _t1 = Transport::parse("console:")
///
/// let _t2 = Transport::parse("file:/var/log/app.log")
/// ```
pub fn Transport::parse(transport : StringView) -> Transport raise {
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
async fn Transport::write(self : Transport, content : Json) -> Unit {
  match self {
    Console => println(content.stringify())
    File(path~, file~) as transport => {
      let file = match file {
        Some(file) => file
        None => {
          let dir : String = [..@path.dirname(path)]
          if !@fs.exists(dir) {
            mkdir(dir)
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
    Channel(channel) => channel.put(content)
    Callback(callback) => callback(content)
    Sink => ()
  }
}

///|
async fn Transport::close(self : Transport) -> Unit {
  match self {
    Console => ()
    File(file=Some(file), ..) => file.close()
    File(..) => ()
    Channel(_) => ()
    Callback(_) => ()
    Sink => ()
  }
}

///|
/// Creates a console transport that outputs to standard output.
///
/// Log messages are written to stdout as JSON strings, one per line.
///
/// # Returns
/// A Transport configured for console output
pub fn Transport::console() -> Transport {
  Transport::Console
}

///|
/// Creates a file transport that writes logs to the specified file.
///
/// # Parameters
/// - `path`: The file path where logs will be written
///
/// # Behavior
/// - Creates parent directories if they don't exist
/// - Opens the file in append mode if it exists
/// - Creates the file with 0o644 permissions if it doesn't exist
/// - Writes each log entry as a JSON object on a separate line
///
/// # Returns
/// A Transport configured for file output
pub fn Transport::file(path : StringView) -> Transport {
  Transport::File(path=path.to_string(), file=None)
}

///|
/// Creates a sink transport that discards all log messages.
///
/// Useful for testing or when logging needs to be disabled without
/// changing the logger configuration.
///
/// # Returns
/// A Transport that silently discards all output
pub fn Transport::sink() -> Transport {
  Transport::Sink
}

///|
/// Creates a channel transport that sends log entries to a queue.
///
/// # Parameters
/// - `queue`: An async queue that will receive Json log objects
///
/// # Returns
/// A Transport that sends logs to the specified queue
///
/// # Note
/// This method is deprecated; the alias "chan" is provided for backward compatibility
#alias(chan, deprecated)
pub fn Transport::channel(queue : @aqueue.Queue[Json]) -> Transport {
  Transport::Channel(queue)
}

///|
/// Creates a callback transport that invokes a custom function for each log entry.
///
/// # Parameters
/// - `callback`: A function that will be called with each Json log object
///
/// # Returns
/// A Transport that delegates log handling to the provided callback
///
/// # Use Cases
/// - Custom log processing or formatting
/// - Integration with external logging systems
/// - Testing and log capture
pub fn Transport::callback(callback : (Json) -> Unit) -> Transport {
  Transport::Callback(callback)
}
