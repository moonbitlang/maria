# `moonbitlang/maria/ai`

High-level AI agent interface for chat-based interactions.

## Overview

This package provides the main AI agent interface for interacting with language models through a conversational API.

## Usage

### Creating an Agent

```moonbit
let agent = @ai.Agent::new(
  model="gpt-4",
  system_prompt="You are a helpful assistant"
)
let _ = agent
```

### Sending Messages

```moonbit
let agent = @ai.Agent::new(model="gpt-4")
let response = agent.chat("What is 2+2?")
// response contains the AI's reply
let _ = response
```

### With Tools

```moonbit
let agent = @ai.Agent::new(
  model="gpt-4",
  tools=[/* tool definitions */]
)
let response = agent.chat("Search for information")
let _ = response
```

## API Reference

### Types

#### `Agent`

An AI agent instance for conversational interactions.

**Methods:**
- `chat(message: String) -> String`: Sends a message and gets response
- `add_tool(tool: Tool)`: Adds a tool to the agent
- `reset()`: Resets conversation history

### Configuration

- Model selection (GPT-4, GPT-3.5, etc.)
- System prompts
- Tool/function calling
- Temperature and other parameters

## Notes

- Built on top of `@openai` package
- Supports streaming responses
- Manages conversation history automatically
- Tool/function calling for extended capabilities
