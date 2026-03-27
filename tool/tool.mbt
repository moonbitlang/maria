///|
pub struct ToolDesc {
  description : String
  name : String
  schema : JsonSchema
} derive(ToJson, Eq, Show)

///|
pub fn ToolDesc::to_openai(
  tool_desc : ToolDesc,
) -> @openai.ChatCompletionToolParam {
  @openai.tool(
    name=tool_desc.name,
    description=tool_desc.description,
    parameters=tool_desc.schema.to_json(),
  )
}

///|
pub fn tool_desc(
  description~ : String,
  name~ : String,
  schema~ : JsonSchema,
) -> ToolDesc {
  ToolDesc::{ description, name, schema }
}

///|
pub(open) trait ToolOutput {
  to_message(Self) -> @ai.Message
}

///|
pub impl ToolOutput for String with to_message(self) {
  @ai.tool_message(content=self, tool_call_id="")
}

///|
pub impl ToolOutput for Json with to_message(self) {
  @ai.tool_message(content=self.stringify(), tool_call_id="")
}

///|
pub struct Tool {
  desc : ToolDesc
  priv f : ToolFn
}

///|
pub(all) struct ToolFn(async (Json) -> ToolResult noraise)

///|
pub enum ToolResult {
  Success(&ToolOutput)
  Failed(Error)
}

///|
#as_free_fn
pub fn ToolResult::success(output : &ToolOutput) -> ToolResult {
  Success(output)
}

///|
pub impl ToJson for ToolResult with to_json(self) {
  match self {
    Success(output) => ["Success", output.to_message().content().to_json()]
    Failed(error) => ["Failed", error.to_json()]
  }
}

///|
pub impl Show for ToolResult with output(self : ToolResult, logger : &Logger) -> Unit {
  match self {
    Success(output) => logger.write_string(output.to_message().content())
    Failed(ToolFailure(message)) => logger.write_string(message)
    Failed(error) => logger.write_string(error.to_json().stringify(indent=2))
  }
}

///|
priv suberror ToolFailure {
  ToolFailure(String)
} derive(ToJson)

///|
#as_free_fn
pub fn ToolResult::failed(message : String) -> ToolResult {
  Failed(ToolFailure(message))
}

///|
///
/// - `description`: Tool description that can be read by the LLM.
/// - `name`: Tool name used by the LLM to call the tool.
/// - `schema`: JSON schema to validate LLM-generated output and provide type information to the LLM.
///             `schema` should be an *object type*. Related issue: [#258](https://github.com/moonbitlang/maria/issues/258)
/// - `f`: Function whose `input` must conform to the `schema` defined above.
///
#as_free_fn
pub fn Tool::new(
  description~ : String,
  name~ : String,
  schema~ : JsonSchema,
  f : ToolFn,
) -> Tool {
  Tool::{ desc: { description, name, schema }, f }
}

///|
#as_free_fn
pub async fn Tool::call(tool : Tool, args : Json) -> ToolResult noraise {
  (tool.f)(args)
}

///|
struct AgentTool(Tool)

///|
pub fn AgentTool::desc(self : AgentTool) -> ToolDesc {
  self.0.desc
}

///|
pub async fn AgentTool::call(
  self : AgentTool,
  args : Json,
) -> ToolResult noraise {
  self.0.call(args)
}

///|
pub fn Tool::to_agent_tool(self : Tool) -> AgentTool {
  AgentTool(self)
}
