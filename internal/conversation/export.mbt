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
fn get_role_title(message : @ai.Message) -> String {
  match message {
    @ai.Message::Assistant(_) => "🤖 Assistant"
    @ai.Message::System(_) => "⚙️ System"
    @ai.Message::Tool(_) => "🔧 Tool"
    @ai.Message::User(_) => "👤 User"
  }
}

///|
fn format_message_content(message : @ai.Message, lines : Array[String]) -> Unit {
  match message {
    @ai.Message::User(content) => format_content_parts(content, lines)
    @ai.Message::Assistant(content, tool_calls~) => {
      // Add assistant content
      if not(content.is_empty()) {
        format_content_parts(content, lines)
      }

      // Handle tool calls
      if not(tool_calls.is_empty()) {
        for tool_call in tool_calls {
          lines.push("")
          let tool_name = tool_call.name
          lines.push(
            "**🔧 Tool Call:** \{get_tool_description(tool_name)} (\{tool_name})",
          )
          if tool_call.arguments is Some(arguments) && !arguments.is_empty() {
            lines.push("")
            lines.push("**Parameters:**")

            // Try to parse arguments as JSON and format nicely
            let args_result = try? @json.parse(arguments)
            match args_result {
              Ok(Json::Object(args_map)) =>
                for key, value in args_map {
                  let value_str = match value {
                    Json::String(s) => s
                    other => other.to_string()
                  }
                  lines.push("- **\{key}:** \{value_str}")
                }
              _ => lines.push("- **raw:** \{arguments}")
            }
          }
        }
      }
    }
    @ai.Message::Tool(content, tool_call_id~) => {
      lines.push("**🔧 Tool:** \{tool_call_id}")
      lines.push("")
      lines.push("**Result:**")
      lines.push("")
      lines.push("```")
      format_content_parts(content, lines)
      lines.push("```")
    }
    @ai.Message::System(content) => format_content_parts(content, lines)
  }
}

///|
fn format_content_parts(content_parts : String, lines : Array[String]) -> Unit {
  if content_parts.is_empty() {
    lines.push("*No content*")
    return
  }
  lines.push(content_parts)
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
