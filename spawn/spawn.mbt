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
  match output {
    Some(output) => {
      let pipe = @process.read_from_process()
      @async.with_task_group(group => {
        group.spawn_bg(() => output.write_string(pipe.0.read_all().text()))
        @process.run(command, arguments, stdout=pipe.1, stderr=pipe.1, cwd?)
      })
    }
    None => @process.run(command, arguments, cwd?)
  }
}
