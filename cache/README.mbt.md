# `moonbitlang/maria/cache`

Prompt caching utilities for OpenAI chat completion messages.

## Overview

This package provides utilities for marking OpenAI chat completion messages for prompt caching, optimizing API calls by reusing previously processed context.

## Usage

### Caching Messages

```moonbit
///|
test "cache messages" {
  let messages = [
    @openai.system_message(content="You are a helpful assistant."),
    @openai.user_message(content="Hello!"),
  ]
  
  let cached_messages = @cache.cache_messages(messages)
  // The last text content in system messages will be marked for caching
  let _ = cached_messages
}
```

## API Reference

### Functions

#### `cache_messages(messages: Array[@openai.ChatCompletionMessageParam]) -> Array[@openai.ChatCompletionMessageParam]`

Processes an array of chat messages to enable prompt caching.

- **Parameters:**
  - `messages`: Array of OpenAI chat completion messages
- **Returns:** Array of messages with caching markers applied

### How It Works

The function:
1. Identifies the last system message in the conversation
2. Finds the last text content part in that message
3. Marks it with `cache_control=Ephemeral` for prompt caching
4. Returns the modified message array

## Notes

- Prompt caching helps reduce API costs by reusing previously processed context
- Only the last text content in system messages is typically cached
- The cache control is set to `Ephemeral`, meaning it's temporary
- This optimization is specific to OpenAI's prompt caching feature
- Cached messages must be used with compatible OpenAI API versions
