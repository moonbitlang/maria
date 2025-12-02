///|
/// Convert an @ai.Message to an OpenAI ChatCompletionMessageParam.
pub fn Message::to_openai(self : Message) -> @openai.ChatCompletionMessageParam {
  match self {
    User(content) => @openai.user_message(content~)
    System(content) => @openai.system_message(content~)
    Assistant(content, tool_calls~) =>
      @openai.assistant_message(
        content~,
        tool_calls=tool_calls.map(ToolCall::to_openai),
      )
    Tool(content, tool_call_id~) =>
      @openai.tool_message(content~, tool_call_id~)
  }
}

///|
/// Convert an OpenAI ChatCompletionMessageParam to an @ai.Message.
pub fn Message::from_openai(
  param : @openai.ChatCompletionMessageParam,
) -> Message {
  match param {
    User(user) => {
      let content = StringBuilder::new()
      for part in user.content {
        match part {
          Text(param) => content.write_string(param.text)
        }
      }
      user_message(content=content.to_string())
    }
    System(system) => {
      let content = StringBuilder::new()
      for part in system.content {
        match part {
          Text(param) => content.write_string(param.text)
        }
      }
      system_message(content=content.to_string())
    }
    Assistant(assistant) => {
      let content = StringBuilder::new()
      for part in assistant.content {
        match part {
          Text(param) => content.write_string(param.text)
        }
      }
      assistant_message(
        content=content.to_string(),
        tool_calls=assistant.tool_calls.map(ToolCall::from_openai_tool_call),
      )
    }
    Tool(tool) => {
      let content = StringBuilder::new()
      for part in tool.content {
        match part {
          Text(param) => content.write_string(param.text)
        }
      }
      tool_message(content=content.to_string(), tool_call_id=tool.tool_call_id)
    }
  }
}

///|
/// Convert an OpenAI ChatCompletionMessage (response message) to an @ai.Message.
pub fn Message::from_openai_response(
  msg : @openai.ChatCompletionMessage,
) -> Message {
  assistant_message(
    content=msg.content.unwrap_or(""),
    tool_calls=msg.tool_calls.map(ToolCall::from_openai_tool_call),
  )
}

///|
/// Convert an @ai.ToolCall to an OpenAI ChatCompletionMessageToolCall.
pub fn ToolCall::to_openai(
  self : ToolCall,
) -> @openai.ChatCompletionMessageToolCall {
  @openai.tool_call(id=self.id, name=self.name, arguments?=self.arguments)
}

///|
/// Convert an OpenAI ChatCompletionMessageToolCall to an @ai.ToolCall.
pub fn ToolCall::from_openai_tool_call(
  tc : @openai.ChatCompletionMessageToolCall,
) -> ToolCall {
  tool_call(id=tc.id, name=tc.function.name, arguments?=tc.function.arguments)
}

///|
/// Convert an @ai.Usage to an OpenAI CompletionUsage.
pub fn Usage::to_openai(self : Usage) -> @openai.CompletionUsage {
  let prompt_tokens_details = self.cache_read_tokens.map(cached_tokens => @openai.PromptTokensDetails::new(
    cached_tokens~,
  ))
  @openai.CompletionUsage::new(
    prompt_tokens=self.input_tokens,
    prompt_tokens_details?,
    completion_tokens=self.output_tokens,
    total_tokens=self.total_tokens,
  )
}

///|
/// Convert an OpenAI CompletionUsage to an @ai.Usage.
pub fn Usage::from_openai(u : @openai.CompletionUsage) -> Usage {
  usage(
    input_tokens=u.prompt_tokens,
    output_tokens=u.completion_tokens,
    cache_read_tokens?=u.prompt_tokens_details.bind(details => details.cached_tokens),
  )
}
