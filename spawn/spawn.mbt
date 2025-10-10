///|
pub async fn spawn(
  command : StringView,
  arguments : Array[StringView],
  output? : &Logger,
  cwd? : StringView,
) -> Int {
  let command = command.to_string()
  let arguments = arguments.map(arg => arg.to_string())
  let cwd = cwd.map(_.to_string())
  if output is Some(output) {
    let (status, data) = @process.collect_output_merged(
      command,
      arguments,
      cwd?,
    )
    output.write_string(data.text())
    status
  } else {
    @process.run(command, arguments, cwd?)
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
