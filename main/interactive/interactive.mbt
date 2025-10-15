///|
pub async fn interactive() -> Unit {
  @async.with_task_group(group => {
    let maria = @maria.Maria::new()
    let rl = @readline.interface(input=@pipe.stdin, output=@pipe.stdout)
    rl.set_prompt("< ")
    group.spawn_bg(() => rl.start())
    while true {
      rl.prompt()
      let content : String = rl.read_line()
      maria.start(content)
    }
  })
}
