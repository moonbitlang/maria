///|
priv struct QueuedMessages(Array[@agent.QueuedMessage])

///|
impl ToJson for QueuedMessages with to_json(
  self : QueuedMessages,
) -> Json {
  let arr : Array[Json] = []
  for m in self.0 {
    arr.push({ "id": m.id, "message": m.message.to_openai().to_json() })
  }
  arr.to_json()
}

///|
async fn Server::get_queued_messages(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let w = JsonResponseWriter::new(w)
  w.write_header(200)
  w.write(QueuedMessages(self.maria.agent.queued_messages()))
}
