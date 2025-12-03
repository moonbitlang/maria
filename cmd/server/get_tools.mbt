///|
priv struct Tool {
  enabled : Bool
}

///|
impl ToJson for Tool with to_json(self : Tool) -> Json {
  Json::object({ "enabled": self.enabled })
}

///|
fn Tool::new(tool : @agent.Tool) -> Tool {
  Tool::{ enabled: tool.enabled() }
}

///|
priv struct Tools(Map[String, Tool])

///|
fn Tools::new(tools : Map[String, @agent.Tool]) -> Tools {
  let tool_map : Map[String, Tool] = {}
  for name, tool in tools {
    tool_map[name] = Tool::new(tool)
  }
  Tools(tool_map)
}

///|
impl ToJson for Tools with to_json(self : Tools) -> Json {
  let obj : Map[String, Json] = {}
  for name, tool in self.0 {
    obj[name] = tool.to_json()
  }
  Json::object(obj)
}

///|
async fn Server::get_tools(self : Server, w : @httpx.ResponseWriter) -> Unit {
  let w = JsonResponseWriter::new(w)
  w.write_header(200)
  w.write(Tools::new(self.maria.agent.tools()))
}
