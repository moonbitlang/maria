# `moonbitlang/maria/agent`

Agent system for managing AI-powered task execution.

## Overview

This package provides an agent framework for managing AI-powered workflows, tool execution, and task orchestration.

## Usage

### Agent Execution

```moonbit
///|
test "run agent" {
  // Agents execute tasks with access to tools and context
  // Typically used as part of the maria CLI system
  let _ = 0
}
```

## API Reference

### Types

#### `Agent`

An agent that can execute tasks using AI and tools.

### Features

- Task planning and execution
- Tool orchestration
- Context management
- Error handling and recovery
- Multi-step workflows

## Notes

- Central component of the maria system
- Integrates with @ai, @tool, @context packages
- Manages conversation state
- Handles tool calling and results
