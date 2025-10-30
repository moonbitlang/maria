///|
/// Spawns a new process asynchronously with the specified command and
/// arguments, optionally capturing output streams.
///
/// Parameters:
///
/// * `command` : The command to execute.
/// * `arguments` : An array of command-line arguments to pass to the command.
/// * `stdin` (optional) : string to be provided as standard input to the process.
/// * `stderr` (optional) : logger to capture standard error output.
/// * `stdout` (optional) : logger to capture standard output.
/// * `cwd` (optional) : working directory for the spawned process.
/// * `env` (optional) : map of environment variables to set for the spawned
///   process.
///
/// Returns the exit status code of the spawned process.
///
/// Example:
///
/// ```moonbit async
/// let output = StringBuilder::new()
/// let status = spawn("echo", ["Hello, World!"], stdout=output)
/// @json.inspect(status, content=0)
/// ```
pub async fn spawn(
  command : StringView,
  arguments : Array[StringView],
  stdin? : String,
  stdout? : &Logger,
  stderr? : &Logger,
  cwd? : StringView,
  env? : Map[String, String],
) -> Int {
  let command = command.to_string()
  let arguments = arguments.map(arg => arg.to_string())
  let cwd = cwd.map(_.to_string())
  @async.with_task_group(group => {
    fn redirect_input(content : String) -> &@process.ProcessInput raise {
      let (stdin, pipe) = @process.write_to_process()
      group.spawn_bg(() => {
        pipe.write(content)
        pipe.close()
      })
      stdin
    }

    fn redirect_output(logger : &Logger) -> &@process.ProcessOutput raise {
      let (pipe, stdout) = @process.read_from_process()
      let buf : FixedArray[Byte] = FixedArray::make(1024, 0)
      group.spawn_bg(() => loop pipe.read(buf) {
        0 => break
        n => {
          let bytes = buf.unsafe_reinterpret_as_bytes()[0:n]
          logger.write_string(@encoding/utf8.decode(bytes))
          continue pipe.read(buf)
        }
      })
      stdout
    }

    let stdin = stdin.map(redirect_input)
    if stdout is Some(stdout) &&
      stderr is Some(stderr) &&
      physical_equal(stdout, stderr) {
      abort("Cannot redirect both stdout and stderr to the same logger")
    }
    let stdout = stdout.map(redirect_output)
    let stderr = stderr.map(redirect_output)
    @process.run(
      command,
      arguments,
      stdin?,
      stdout?,
      stderr?,
      cwd?,
      extra_env?=env,
    )
  })
}

///|
pub extern "c" fn getpid() -> Int = "moonbit_maria_process_getpid"

///|
pub extern "c" fn getppid() -> Int = "moonbit_maria_process_getppid"

///|
extern "c" fn process_kill(pid : Int, sig : Int) -> Int = "moonbit_maria_process_kill"

///|
pub fn kill(pid : Int, sig : Int) -> Unit raise @errno.Errno {
  let status = process_kill(pid, sig)
  if status != 0 {
    raise @errno.Errno(status)
  }
}
