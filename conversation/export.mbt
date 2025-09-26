///|
pub fn Conversation::export_to_markdown(self : Conversation) -> String {
  let lines = []

  // Add conversation ID as level 1 heading
  lines.push("# Conversation: \{self.id}")
  lines.push("")

  // Add metadata
  lines.push("**Name:** \{self.name}")
  if self.description is Some(description) {
    lines.push("**Description:** \{description}")
  }
  lines.push("**Created:** \{format_timestamp(self.created_at)}")
  lines.push("**Updated:** \{format_timestamp(self.updated_at)}")
  lines.push("**Messages:** \{self.messages.length()}")
  lines.push("")

  // Add messages
  for i in 0..<self.messages.length() {
    let message = self.messages[i]
    // Role as level 2 heading
    let role_title = get_role_title(message.message)
    lines.push("## \{role_title}")
    lines.push("")

    // Content as level 3 heading and body
    lines.push("### Content")
    lines.push("")

    // Add message content
    format_message_content(message.message, lines)

    // Add metadata if available
    lines.push("")
    lines.push("**Timestamp:** \{format_timestamp(message.timestamp)}")

    // Add separator between messages (except for last message)
    if i < self.messages.length() - 1 {
      lines.push("")
      lines.push("---")
      lines.push("")
    }
  }
  lines.join("\n")
}

///|
fn format_timestamp(timestamp : Int64) -> String {
  // Convert Unix timestamp to a readable format
  // For now, just return the timestamp as string since we don't have date formatting utilities
  // In a real implementation, you'd want to format this as a proper date/time string
  timestamp.to_string()
}

///|
fn get_role_title(message : @openai.ChatCompletionMessageParam) -> String {
  match message {
    @openai.ChatCompletionMessageParam::Assistant(_) => "🤖 Assistant"
    @openai.ChatCompletionMessageParam::System(_) => "⚙️ System"
    @openai.ChatCompletionMessageParam::Tool(_) => "🔧 Tool"
    @openai.ChatCompletionMessageParam::User(_) => "👤 User"
  }
}

///|
fn format_message_content(
  message : @openai.ChatCompletionMessageParam,
  lines : Array[String],
) -> Unit {
  match message {
    @openai.ChatCompletionMessageParam::User(user_msg) =>
      format_content_parts(user_msg.content, lines)
    @openai.ChatCompletionMessageParam::Assistant(assistant_msg) => {
      // Add assistant content
      if not(assistant_msg.content.is_empty()) {
        format_content_parts(assistant_msg.content, lines)
      }

      // Handle tool calls
      if not(assistant_msg.tool_calls.is_empty()) {
        for tool_call in assistant_msg.tool_calls {
          lines.push("")
          let tool_name = tool_call.function.name
          lines.push(
            "**🔧 Tool Call:** \{get_tool_description(tool_name)} (\{tool_name})",
          )
          if not(tool_call.function.arguments.is_empty()) {
            lines.push("")
            lines.push("**Parameters:**")

            // Try to parse arguments as JSON and format nicely
            let args_result = try? @json.parse(tool_call.function.arguments)
            match args_result {
              Ok(Json::Object(args_map)) =>
                for key, value in args_map {
                  let value_str = match value {
                    Json::String(s) => s
                    other => other.to_string()
                  }
                  lines.push("- **\{key}:** \{value_str}")
                }
              _ => lines.push("- **raw:** \{tool_call.function.arguments}")
            }
          }
        }
      }
    }
    @openai.ChatCompletionMessageParam::Tool(tool_msg) => {
      lines.push("**🔧 Tool:** \{tool_msg.tool_call_id}")
      lines.push("")
      lines.push("**Result:**")
      lines.push("")
      lines.push("```")
      format_content_parts(tool_msg.content, lines)
      lines.push("```")
    }
    @openai.ChatCompletionMessageParam::System(system_msg) =>
      format_content_parts(system_msg.content, lines)
  }
}

///|
fn format_content_parts(
  content_parts : Array[@openai.ChatCompletionContentPartParam],
  lines : Array[String],
) -> Unit {
  if content_parts.is_empty() {
    lines.push("*No content*")
    return
  }
  for part in content_parts {
    match part {
      @openai.ChatCompletionContentPartParam::Text(text_part) =>
        if not(text_part.text.is_empty()) {
          lines.push(text_part.text)
        }
    }
  }
}

///|
fn get_tool_description(tool_name : String) -> String {
  // Tool descriptions for better formatting
  match tool_name {
    "ask_followup_question" => "Ask follow-up question"
    "attempt_completion" => "Complete task"
    "create_file" => "Create file"
    "execute_command" => "Execute command"
    "list_files" => "List files"
    "read_file" => "Read file"
    "write_file" => "Write file"
    "search_files" => "Search files"
    "check_moonbit_project" => "Check MoonBit project"
    "get_moonbit_coverage" => "Get MoonBit coverage"
    "meta_write_to_file" => "Meta write to file"
    "fix_moonbit_warnings" => "Fix MoonBit warnings"
    _ => "Execute \{tool_name}"
  }
}
