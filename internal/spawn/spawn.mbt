///|
/// Spawns a new process asynchronously with the specified command and
/// arguments, optionally capturing output streams.
///
/// Parameters:
///
/// * `command` : The command to execute.
/// * `arguments` : An array of command-line arguments to pass to the command.
/// * `stderr` : Optional logger to capture standard error output.
/// * `stdout` : Optional logger to capture standard output.
/// * `cwd` : Optional working directory for the spawned process.
/// * `env` : Optional map of environment variables to set for the spawned
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
  stderr? : &Logger,
  stdout? : &Logger,
  cwd? : StringView,
  env? : Map[String, String],
) -> Int {
  let command = command.to_string()
  let arguments = arguments.map(arg => arg.to_string())
  let cwd = cwd.map(_.to_string())
  match (stdout, stderr) {
    (Some(stdout), Some(stderr)) if physical_equal(stdout, stderr) => {
      let (status, data) = @process.collect_output_merged(
        command,
        arguments,
        cwd?,
        extra_env?=env,
      )
      stdout.write_string(data.text())
      status
    }
    (Some(stdout), Some(stderr)) => {
      let (status, out_data, err_data) = @process.collect_output(
        command,
        arguments,
        cwd?,
        extra_env?=env,
      )
      stdout.write_string(out_data.text())
      stderr.write_string(err_data.text())
      status
    }
    (Some(stdout), None) => {
      let (status, out_data) = @process.collect_stdout(
        command,
        arguments,
        cwd?,
        extra_env?=env,
      )
      stdout.write_string(out_data.text())
      status
    }
    (None, Some(stderr)) => {
      let (status, err_data) = @process.collect_stderr(
        command,
        arguments,
        cwd?,
        extra_env?=env,
      )
      stderr.write_string(err_data.text())
      status
    }
    (None, None) => @process.run(command, arguments, cwd?, extra_env?=env)
  }
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
