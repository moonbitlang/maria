# `moonbitlang/maria/openai`

OpenAI API client for chat completions and embeddings.

## Overview

This package provides a complete OpenAI API client with support for chat completions, function calling, and structured responses.

## Usage

### Chat Completions

```moonbit
let param = @openai.chat_completion_param(
  model="gpt-4",
  messages=[
    @openai.system_message(content="You are helpful"),
    @openai.user_message(content="Hello!")
  ]
)

let response = @openai.chat_completion(param)
// response contains the model's reply
let _ = response
```

### Function Calling

```moonbit
let tool = @openai.tool(
  name="get_weather",
  description="Get weather for a location",
  parameters={
    "type": "object",
    "properties": {
      "location": {"type": "string"}
    },
    "required": ["location"]
  }
)

let param = @openai.chat_completion_param(
  model="gpt-4",
  messages=[/* messages */],
  tools=[tool]
)

let response = @openai.chat_completion(param)
// Check for tool calls in response
let _ = response
```

### Message Types

```moonbit
// System message
let sys = @openai.system_message(content="You are helpful")

// User message
let user = @openai.user_message(content="Hello")

// Assistant message
let asst = @openai.assistant_message(content="Hi there!")

// Tool result message
let tool_result = @openai.tool_message(
  content="Result data",
  tool_call_id="call_123"
)

let _ = (sys, user, asst, tool_result)
```

## API Reference

### Functions

#### `chat_completion(param: ChatCompletionParam) -> ChatCompletion`

Sends a chat completion request to OpenAI.

#### `chat_completion_param(model: String, messages: Array[ChatCompletionMessageParam], tools?: Array[ChatCompletionToolParam], ...) -> ChatCompletionParam`

Creates chat completion parameters.

#### Message Builders

- `system_message(content: String | Array[ContentPart]) -> ChatCompletionMessageParam`
- `user_message(content: String | Array[ContentPart]) -> ChatCompletionMessageParam`
- `assistant_message(content: String | Array[ContentPart], tool_calls?: Array[ToolCall]) -> ChatCompletionMessageParam`
- `tool_message(content: String | Array[ContentPart], tool_call_id: String) -> ChatCompletionMessageParam`

#### Tool Builders

- `tool(name: String, description: String, parameters: Json) -> ChatCompletionToolParam`
- `text_content_part(text: String, cache_control?: CacheControl) -> ChatCompletionContentPartParam`

### Types

#### `ChatCompletion`

Response from chat completion API.

#### `ChatCompletionParam`

Parameters for chat completion request.

#### `ChatCompletionMessageParam`

A message in the conversation (System, User, Assistant, or Tool).

#### `ChatCompletionToolParam`

A tool/function definition.

#### `ToolCall`

A tool call made by the assistant.

## Configuration

Set your API key:
```bash
export OPENAI_API_KEY=your_api_key_here
```

## Notes

- Supports GPT-4, GPT-3.5-turbo, and other OpenAI models
- Function calling for tool integration
- Streaming responses available
- Prompt caching support
- Rate limiting and error handling
- JSON mode for structured outputs
