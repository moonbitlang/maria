///|
async fn main {
  @backtrace.initialize()
  let args = @os.args()
  match args[1:] {
    ["migrate", .. rest] => @migrator.migrate(rest)
    ["conversations"] => @conversation.list()
    ["conversation", .. rest] => @conversation.show(rest)
    ["server", .. rest] => @server.start(rest)
    ["daemon", .. rest] => @daemon.start(rest)
    ["login"] => @login.login()
    ["version"] => println(@buildinfo.version)
    [.. rest] => @interactive.interactive(rest)
  }
}
