///|
async test "format_log_entry/PostToolCall" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "PostToolCall",
    "name": "get_weather",
    "text": "The weather in New York is sunny.",
  }
  formatter.format_log_entry(log_entry)
  inspect(
    formatter.to_string(),
    content=(
      #|# 1 Tool call result: <get_weather>
      #|
      #|````markdown
      #|The weather in New York is sunny.
      #|````
      #|
    ),
  )
}

///|
async test "format_log_entry/MessageAdded with multiline tool content" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "tool",
      "tool_call_id": "call_123",
      "content": [
        {
          "type": "text",
          "text": "✅ Operation completed: Marked task as completed\n\n📝 Current todo list:\n  🟡 ✅ [ea45749e] Create project structure\n  🟡 ⏳ [1efbf50f] Define data structures\n\n📊 Summary: Total 2 items",
        },
      ],
    },
  }
  formatter.format_log_entry(log_entry)
  // The tool message should be ignored and produce no output, as the result
  // is already logged in PostToolCall.
  inspect(formatter.to_string(), content="")
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "system",
      "content": [
        { "type": "text", "text": "System maintenance scheduled at midnight." },
      ],
    },
  }
  formatter.format_log_entry(log_entry)
  // The system message should be ignored and produce no output.
  inspect(formatter.to_string(), content="")
}

///|
async test "format_log_entry/MessageAdded" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "user",
      "content": [{ "type": "text", "text": "Hello, how are you?" }],
    },
  }
  formatter.format_log_entry(log_entry)
  inspect(
    formatter.to_string(),
    content=(
      #|# 1 User: Hello, how are you?
      #|
      #|Hello, how are you?
      #|
    ),
  )
}

///|
async test "format_log_entry/RequestCompleted" {
  let formatter = Formatter::new("test.md")
  let log_entry : Json = {
    "msg": "RequestCompleted",
    "message": {
      "role": "assistant",
      "content": "I am fine, thank you!",
      "tool_calls": [
        {
          "id": "tool_call_1",
          "function": {
            "name": "get_weather",
            "arguments": "{\"location\": \"New York\"}",
          },
        },
      ],
    },
  }
  formatter.format_log_entry(log_entry)
  inspect(
    formatter.to_string(),
    content=(
      #|# 1 Assistant: I am fine, thank you!
      #|
      #|I am fine, thank you!
      #|
      #|## Tool call argument: <get_weather>
      #|
      #|<location>
      #|  New York
      #|</location>
      #|
    ),
  )
}
