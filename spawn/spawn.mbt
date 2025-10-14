///|
pub async fn spawn(
  command : StringView,
  arguments : Array[StringView],
  stderr? : &Logger,
  stdout? : &Logger,
  cwd? : StringView,
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
      )
      stdout.write_string(data.text())
      status
    }
    (Some(stdout), Some(stderr)) => {
      let (status, out_data, err_data) = @process.collect_output(
        command,
        arguments,
        cwd?,
      )
      stdout.write_string(out_data.text())
      stderr.write_string(err_data.text())
      status
    }
    (Some(stdout), None) => {
      let (status, out_data) = @process.collect_stdout(command, arguments, cwd?)
      stdout.write_string(out_data.text())
      status
    }
    (None, Some(stderr)) => {
      let (status, err_data) = @process.collect_stderr(command, arguments, cwd?)
      stderr.write_string(err_data.text())
      status
    }
    (None, None) => @process.run(command, arguments, cwd?)
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
