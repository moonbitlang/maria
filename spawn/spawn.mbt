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
