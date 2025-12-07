///|
struct Tool {
  mut enabled : Bool
  tool : @tool.AgentTool
}

///|
fn Tool::new(tool : @tool.AgentTool) -> Tool {
  Tool::{ enabled: true, tool }
}

///|
pub fn Tool::desc(self : Tool) -> @tool.ToolDesc {
  self.tool.desc()
}

///|
async fn Tool::call(
  self : Tool,
  args : Json,
) -> @tool.ToolResult[(Json, String)] noraise {
  guard self.enabled else {
    return @tool.error("Tool '\{self.tool.desc().name}' is disabled.")
  }
  self.tool.call(args)
}

///|
pub fn Tool::enabled(self : Tool) -> Bool {
  self.enabled
}

///|
/// Enables or disables tools based on the provided set of tool names.
///
/// Parameters:
///
/// * `agent` : The agent instance whose tools will be enabled or disabled.
/// * `tool_names` : A set containing the names of tools that should be enabled.
///   Tools not in this set will be disabled.
pub async fn Agent::set_enabled_tools(
  agent : Agent,
  tool_names : Set[String],
) -> Unit {
  for name, tool in agent.tools {
    if tool_names.contains(name) {
      tool.enabled = true
    } else {
      tool.enabled = false
    }
  }
}

///|
pub fn Agent::tools(self : Agent) -> Map[String, Tool] {
  self.tools
}

///|
/// Executes a tool call requested by the AI model and returns the result.
///
/// This function handles the complete tool execution lifecycle:
/// 1. Validates that the requested tool exists
/// 2. Emits a `PreToolCall` event for logging/monitoring
/// 3. Parses and validates the tool arguments
/// 4. Executes the tool with the provided arguments
/// 5. Emits a `PostToolCall` event with the result
/// 6. Returns the result formatted as a tool message
///
/// Parameters:
///
/// * `agent` : The agent instance containing the available tools.
/// * `tool_call` : The tool call request from the AI model, containing the tool
///   name, arguments, and call ID.
///
/// Returns a `@ai.Message` containing either:
/// * The tool's successful output
/// * An error message if the tool doesn't exist, arguments are invalid, or
///   execution fails
///
/// The returned message maintains the `tool_call_id` to correlate with the
/// original request.
async fn Agent::execute_tool(
  agent : Agent,
  tool_call : @ai.ToolCall,
) -> @ai.Message {
  guard agent.tools.get(tool_call.name) is Some(tool) else {
    @ai.tool_message(
      content="Unknown tool: \{tool_call.name}",
      tool_call_id=tool_call.id,
    )
  }
  agent.emit(PreToolCall(tool_call))
  let arguments : Json = match tool_call.arguments {
    None | Some("") =>
      // when models like haiku return empty arguments, we treat it as empty object 
      {}
    Some(arguments) =>
      @json.parse(arguments) catch {
        error =>
          return @ai.tool_message(
            content="Error parsing tool arguments: \{error}, arguments: \{arguments}",
            tool_call_id=tool_call.id,
          )
      }
  }
  let (result, rendered) = match tool.call(arguments) {
    Ok((json, text)) => (Ok(json), text)
    Error(error, text) => (Err(error), text)
  }
  agent.emit(PostToolCall(tool_call, result~, rendered~))
  @ai.tool_message(content=rendered, tool_call_id=tool_call.id)
}

///|
/// Adds multiple tools to the agent's available tools collection.
///
/// This is a convenience function for adding multiple `AgentTool` instances
/// at once. Each tool is added individually and triggers a `ToolAdded` event.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tools to.
/// * `tools` : An array of `AgentTool` instances to be registered with the agent.
pub fn Agent::add_tools(agent : Agent, tools : Array[@tool.AgentTool]) -> Unit {
  for tool in tools {
    agent.add_agent_tool(tool)
  }
}

///|
/// Adds a single agent tool to the agent's tools collection.
///
/// The tool is indexed by its name in the agent's tool map and a `ToolAdded`
/// event is emitted for logging and monitoring purposes.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tool to.
/// * `tool` : The agent tool to register.
fn Agent::add_agent_tool(agent : Agent, tool : @tool.AgentTool) -> Unit {
  let desc = tool.desc()
  agent.tools[desc.name] = Tool::new(tool)
  agent.emit(ToolAdded(desc))
}

///|
/// Adds a tool to the agent's available tools collection.
///
/// Parameters:
///
/// * `agent` : The agent instance to add the tool to.
/// * `tool` : The tool to be added, which will be indexed by its name for
///   future tool calls.
pub fn[Output : ToJson + Show] Agent::add_tool(
  agent : Agent,
  tool : @tool.Tool[Output],
) -> Unit {
  agent.add_agent_tool(tool.to_agent_tool())
}

///|
///  Build the tools array for this API call
/// Convert each registered tool into OpenAI's tool parameter format
fn Agent::tools_desc(self : Agent) -> Array[@tool.ToolDesc] {
  let descs = []
  for _, tool in self.tools {
    if tool.enabled {
      descs.push(tool.desc())
    }
  }
  descs
}
