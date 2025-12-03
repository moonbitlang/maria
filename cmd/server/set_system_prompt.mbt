///|
priv struct SystemPrompt(String?)

///|
impl @json.FromJson for SystemPrompt with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> SystemPrompt raise @json.JsonDecodeError {
  let system_prompt : String? = match json {
    Null => None
    _ => Some(@json.from_json(json, path=json_path))
  }
  SystemPrompt(system_prompt)
}

///|
async fn Server::set_system_prompt(
  self : Server,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  let r = JsonRequestReader::new(r)
  let w = JsonResponseWriter::new(w)
  let req : SystemPrompt = r.read()
  self.maria.agent.set_system_prompt(req.0)
  w.write_header(200)
  w.write_json({})
}
