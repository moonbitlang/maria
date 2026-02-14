///|
fn cache_content_parts(
  parts : Array[@openai.ChatCompletionContentPartParam],
) -> Array[@openai.ChatCompletionContentPartParam] {
  // find the last text content part
  let parts_length = parts.length()
  let (index, text) = for i in 0..<parts_length {
    let i = parts_length - 1 - i
    match parts[i] {
      Text(text) => break (i, text.text)
    }
  } nobreak {
    return parts
  }
  let cached = []
  for i in 0..<index {
    cached.push(parts[i])
  }
  cached.push(@openai.text_content_part(text, cache_control=Ephemeral))
  for i in (index + 1)..<parts.length() {
    cached.push(parts[i])
  }
  cached
}

///|
fn cache_message(
  message : @openai.ChatCompletionMessageParam,
) -> @openai.ChatCompletionMessageParam {
  match message {
    System(system) =>
      @openai.system_message(content=cache_content_parts(system.content))
    User(user) =>
      @openai.user_message(content=cache_content_parts(user.content))
    Assistant(assistant) =>
      @openai.assistant_message(content=cache_content_parts(assistant.content))
    Tool(tool) =>
      @openai.tool_message(
        content=cache_content_parts(tool.content),
        tool_call_id=tool.tool_call_id,
      )
  }
}

///|
pub fn cache_messages(
  messages : ArrayView[@openai.ChatCompletionMessageParam],
) -> Array[@openai.ChatCompletionMessageParam] {
  let mut last_system : @openai.ChatCompletionSystemMessageParam? = None
  let cached = []
  let messages = for messages = messages {
    if last_system is Some(system) {
      cached.push(
        @openai.system_message(content=cache_content_parts(system.content)),
      )
    }
    match messages {
      [System(system), .. messages] => {
        last_system = Some(system)
        continue messages
      }
      _ => break messages
    }
  }
  // find the last two user/tool messages.
  let user_tool_indices = []
  for i in 0..<messages.length() {
    match messages[i] {
      User(_) | Tool(_) => user_tool_indices.push(i)
      _ => continue
    }
  }
  match user_tool_indices {
    [] =>
      for message in messages {
        cached.push(message)
      }
    [last] => {
      for i in 0..<last {
        cached.push(messages[i])
      }
      cached.push(cache_message(messages[last]))
    }
    [.., second_last, last] => {
      for i in 0..<second_last {
        cached.push(messages[i])
      }
      cached.push(cache_message(messages[second_last]))
      for i in (second_last + 1)..<last {
        cached.push(messages[i])
      }
      cached.push(cache_message(messages[last]))
    }
  }
  cached
}
