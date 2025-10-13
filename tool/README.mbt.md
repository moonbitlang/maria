# `moonbitlang/maria/tool`

Tool registry and management system for AI agent tools.

## Overview

This package provides the core tool system for registering and managing tools that AI agents can use.

## API Reference

### Types

#### `Tool`

Represents a callable tool for AI agents.

### Functions

#### `register(tool: Tool) -> Unit`

Registers a new tool in the system.

#### `list() -> Array[Tool]`

Lists all registered tools.

#### `find(name: String) -> Tool?`

Finds a tool by name.

## Notes

- Tools are functions the AI can call
- Each tool has a name, description, and parameters schema
- Tools are defined in sub-packages (tool/read_file, tool/write_to_file, etc.)
- The agent system uses these tools to perform actions
