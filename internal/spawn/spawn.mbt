///|
pub struct CompletedProcess {
  status : Int
  stdout : String
  stderr : String
  elapsed : Int
  timeout : Int?
}

///|
pub fn CompletedProcess::check(self : CompletedProcess) -> Unit raise Failed {
  if self.status != 0 {
    raise Failed(self)
  }
}

///|
pub suberror Failed CompletedProcess

///|
pub suberror TimedOut {
  TimedOut(timeout~ : Int, stdout~ : String, stderr~ : String)
}

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
  timeout? : Int,
  cwd? : StringView,
  env? : Map[String, String],
) -> CompletedProcess {
  let command = command.to_string()
  let arguments = arguments.map(arg => arg.to_string())
  let cwd = cwd.map(_.to_string())
  @async.with_task_group(group => {
    fn redirect_input(content : String) -> &@process.ProcessInput raise {
      let (input, pipe) = @process.write_to_process()
      group.spawn_bg(() => {
        defer pipe.close()
        pipe.write(content)
      })
      input
    }

    let stdin = stdin.map(redirect_input)
    fn redirect_output() raise {
      let (pipe, output) = @process.read_from_process()
      let task = group.spawn(() => {
        defer pipe.close()
        @encoding/utf8.decode_lossy(pipe.read_all().binary())
      })
      (task, output)
    }

    let stdout = redirect_output()
    let stderr = redirect_output()
    async fn run() -> Int {
      @process.run(
        command,
        arguments,
        cwd?,
        stdin?,
        stdout=stdout.1,
        stderr=stderr.1,
        extra_env?=env,
      )
    }

    let clock = @clock.epoch
    let t0 = clock.now()
    let status = if timeout is Some(timeout) {
      @async.with_timeout(timeout, run) catch {
        @async.TimeoutError =>
          raise TimedOut(
            timeout~,
            stdout=stdout.0.wait(),
            stderr=stderr.0.wait(),
          )
        error => raise error
      }
    } else {
      run()
    }
    let t1 = clock.now()
    let elapsed = (t1 - t0).to_int()
    CompletedProcess::{
      status,
      stdout: stdout.0.wait(),
      stderr: stderr.0.wait(),
      elapsed,
      timeout,
    }
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
