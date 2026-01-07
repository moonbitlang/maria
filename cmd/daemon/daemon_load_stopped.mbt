///|
/// Loads all existing stopped conversations from storage and adds them as
/// stopped tasks to the daemon.
///
/// Parameters:
///
/// * `self` : The daemon instance to load conversations into.
async fn Daemon::load_stopped(self : Daemon) -> Unit {
  let ids = self.conversations.list()
  println("[INFO] (Daemon) Loading existing conversations: \{ids}")
  for id in ids {
    guard self.conversations.load(id) is Some(conversation) else {
      println(
        "[WARN] (Daemon) Failed to load conversation '\{id}', skipping...",
      )
      continue
    }
    println(
      "[INFO] (Daemon) Loaded conversation '\{conversation.id()}' at cwd '\{conversation.cwd()}'",
    )
    let cwd = conversation.cwd()
    let id = conversation.id()
    if self.by_id.get(id) is Some(_) {
      continue
    }
    let broadcast : @broadcast.Broadcast[@server.ServerStreamEvent] = @broadcast.Broadcast::new()
    for event in conversation.events() {
      broadcast.put(Maria(event))
    }
    let task : Stopped = {
      name: Some(conversation.name()),
      id,
      cwd,
      created: conversation.created(),
      updated: conversation.updated(),
      web_search: conversation.web_search(),
      broadcast,
    }
    self.by_id[id] = Stopped(task)
  }
}
