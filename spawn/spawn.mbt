///|
pub async fn spawn(
  command : StringView,
  arguments : Array[StringView],
  output? : &Logger,
  cwd? : StringView,
) -> Int {
  let command = @encoding/utf8.encode(command)
  let arguments = arguments.map(arg => @encoding/utf8.encode(arg))
  let cwd = cwd.map(@encoding/utf8.encode(_))
  match output {
    Some(output) => {
      let pipe = @process.read_from_process()
      @async.with_task_group(g => {
        g.spawn_bg(() => {
          let buf : FixedArray[Byte] = FixedArray::make(4096, 0)
          loop pipe.0.read(buf) {
            0 => break
            n => {
              output.write_string(
                @encoding/utf8.decode_lossy(
                  buf.unsafe_reinterpret_as_bytes()[0:n],
                ),
              )
              continue pipe.0.read(buf)
            }
          }
        })
        @process.run(command, arguments, stdout=pipe.1, stderr=pipe.1, cwd?)
      })
    }
    None => @process.run(command, arguments, cwd?)
  }
}
