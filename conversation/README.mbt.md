# `moonbitlang/maria/conversation`

Conversation history management for AI interactions.

## Overview

This package manages conversation history, including messages, tool calls, and state persistence.

## Usage

### Creating a Conversation

```moonbit
let conv = @conversation.Conversation::new()
let _ = conv
```

### Adding Messages

```moonbit
let conv = @conversation.Conversation::new()

conv.add_user_message("Hello")
conv.add_assistant_message("Hi there!")

let messages = conv.messages()
messages.length() // 2
```

## API Reference

### Types

#### `Conversation`

Manages conversation history.

**Methods:**
- `new() -> Conversation`: Creates new conversation
- `add_user_message(content: String)`: Adds user message
- `add_assistant_message(content: String)`: Adds assistant message
- `add_tool_call(tool_call: ToolCall)`: Records tool call
- `add_tool_result(result: String, tool_call_id: String)`: Adds tool result
- `messages() -> Array[ChatCompletionMessageParam]`: Gets all messages
- `clear()`: Clears history
- `save(path: String)`: Saves to file
- `load(path: String)`: Loads from file

## Notes

- Persistent conversation storage
- Tool call tracking
- Message filtering and truncation
- Context window management
