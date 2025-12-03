///|
async fn Server::get_system_prompt(
  self : Server,
  w : @httpx.ResponseWriter,
) -> Unit {
  let res : Json = match self.maria.agent.system_prompt() {
    Some(sys) => sys.to_json()
    None => Json::null()
  }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(res.stringify())
}
