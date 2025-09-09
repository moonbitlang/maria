///|
fn main {
  @async.with_event_loop(group => {
    let rl = @readline.interface(input=@pipe.stdin, output=@pipe.stdout)
    defer rl.close()
    let task = group.spawn(() => rl.start())
    loop rl.read_line() {
      line => {
        println("readline: \{line}")
        continue rl.read_line()
      }
    }
    task.cancel()
  }) catch {
    error => println("Error: \{error}")
  }
}
