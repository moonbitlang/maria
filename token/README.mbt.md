# `moonbitlang/maria/token`

Token counting for OpenAI chat completion API.

## Overview

This package provides utilities for counting tokens in OpenAI chat completion requests, helping to manage API costs and stay within model limits.

## Usage

### Creating a Token Counter

```moonbit
///|
test "create counter" {
  let counter = @token.Counter::new()
  let _ = counter
}
```

### Counting String Tokens

```moonbit
///|
test "count string" {
  let counter = @token.Counter::new()
  let token_count = counter.count_string("Hello, World!")
  // Returns token count including system overhead
  let _ = token_count
}
```

### Counting Messages

```moonbit
///|
test "count messages" {
  let counter = @token.Counter::new()
  let messages = [
    @openai.user_message(content="What is 2+2?"),
    @openai.assistant_message(content="2+2 equals 4."),
  ]
  
  // Manually count messages
  let mut total = 0
  for msg in messages {
    total += counter.count_message(msg)
  }
  let _ = total
}
```

### Counting Tools

```moonbit
///|
test "count with tools" {
  let counter = @token.Counter::new()
  let tool = @openai.tool(
    name="get_weather",
    description="Get current weather",
    parameters={
      "type": "object",
      "properties": {
        "location": {"type": "string"}
      }
    }
  )
  
  counter.add_tool(tool)
  // Counter now includes tool overhead
  let _ = counter
}
```

### Counting Complete Request

```moonbit
///|
test "count full request" {
  let counter = @token.Counter::new()
  let param = @openai.chat_completion_param(
    model="gpt-4",
    messages=[
      @openai.system_message(content="You are a helpful assistant."),
      @openai.user_message(content="Hello!"),
    ],
    tools=[
      @openai.tool(
        name="search",
        description="Search for information",
        parameters={"type": "object", "properties": {}}
      )
    ]
  )
  
  let total_tokens = counter.count_param(param)
  // Returns total token count for the entire request
  let _ = total_tokens
}
```

## API Reference

### Types

#### `Counter`

Token counter for OpenAI chat completions using the cl100k_base encoding.

**Methods:**
- `new() -> Counter raise`: Creates a new counter with cl100k_base encoding
- `count_string(text: String) -> Int raise`: Counts tokens in a string (includes overhead)
- `count_message(message: @openai.ChatCompletionMessageParam) -> Int raise`: Counts tokens in a single message
- `add_tool(tool: @openai.ChatCompletionToolParam) raise`: Adds a tool to the counter (updates overhead)
- `count_param(param: @openai.ChatCompletionParam) -> Int raise`: Counts total tokens for a complete request

### Constants

- `SystemOverhead: Int = 7`: Base overhead for system messages
- `ToolsOverhead: Int = 320`: Overhead added when tools are present
- `ToolOverhead: Int = 20`: Base overhead per tool

### Token Counting Details

The counter accounts for:
- System message overhead (7 tokens)
- Tools overhead (320 tokens if any tools present)
- Per-tool overhead (20 tokens + content)
- Message content (text, tool calls, etc.)
- Function names and arguments
- Tool call IDs

## Notes

- Uses tiktoken's cl100k_base encoding (for GPT-3.5 and GPT-4)
- Tool parameter descriptions are counted with 2x weight
- Complex JSON schemas in tool parameters use approximate counting
- Token counts are estimates and may vary slightly from actual API usage
- Overhead values are based on OpenAI's token counting methodology
