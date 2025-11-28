///|
pub fn ChatCompletionMessage::to_ai_message(
  self : ChatCompletionMessage,
) -> @ai.Message {
  @ai.assistant_message(
    content=self.content.unwrap_or(""),
    tool_calls=self.tool_calls.map(tc => @ai.tool_call(
      id=tc.id,
      name=tc.function.name,
      arguments?=tc.function.arguments,
    )),
  )
}

///|
pub fn ChatCompletionMessageParam::from_ai_message(
  self : @ai.Message,
) -> ChatCompletionMessageParam {
  match self {
    User(content) => user_message(content~)
    System(content) => system_message(content~)
    Assistant(content, tool_calls~) =>
      assistant_message(
        content~,
        tool_calls=tool_calls.map(tc => ChatCompletionMessageToolCall::from_ai_tool_call(
          tc,
        )),
      )
    Tool(content, tool_call_id~) => tool_message(content~, tool_call_id~)
  }
}

///|
pub fn ChatCompletionMessageToolCall::from_ai_tool_call(
  self : @ai.ToolCall,
) -> ChatCompletionMessageToolCall {
  tool_call(id=self.id, name=self.name, arguments?=self.arguments)
}

///|
pub fn CompletionUsage::to_ai_usage(usage : CompletionUsage) -> @ai.Usage {
  @ai.usage(
    input_tokens=usage.prompt_tokens,
    output_tokens=usage.completion_tokens,
    cache_read_tokens?=usage.prompt_tokens_details.bind(details => details.cached_tokens),
  )
}

///|
pub fn CompletionUsage::from_ai_usage(usage : @ai.Usage) -> CompletionUsage {
  let prompt_tokens_details = if usage.cache_read_tokens is Some(_) {
    Some(PromptTokensDetails::{
      cached_tokens: usage.cache_read_tokens,
      audio_tokens: None,
    })
  } else {
    None
  }
  CompletionUsage::{
    prompt_tokens: usage.input_tokens,
    prompt_tokens_details,
    completion_tokens: usage.output_tokens,
    completion_tokens_details: None,
    total_tokens: usage.total_tokens,
    cost: None,
    cost_details: None,
  }
}

///|
pub fn ChatCompletionMessageToolCall::to_ai_tool_call(
  self : ChatCompletionMessageToolCall,
) -> @ai.ToolCall {
  @ai.tool_call(
    id=self.id,
    name=self.function.name,
    arguments?=self.function.arguments,
  )
}

///|
pub fn ChatCompletionToolParam::from_tool_desc(
  desc : @tool.ToolDesc,
) -> ChatCompletionToolParam {
  tool(
    name=desc.name,
    description=desc.description,
    parameters=desc.schema.to_json(),
  )
}
