///|
async fn main {
  @backtrace.initialize()
  let args = @os.args()
  match args[1:] {
    ["migrate", .. rest] => @migrator.migrate(rest)
    ["exec" | "execute" | "-p", prompt] =>
      if @tty.isatty(@pipe.stdin.fd()) {
        @interactive.interactive(prompt~)
      } else {
        @executor.execute(args)
      }
    ["conversations"] => @conversation.list()
    ["conversation", .. rest] => @conversation.show(rest)
    [unknown, ..] => raise @argument.InvalidArgument(unknown)
    [] => @interactive.interactive()
  }
}
