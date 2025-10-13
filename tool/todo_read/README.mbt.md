# `moonbitlang/maria/tool/todo_read`

Reads the current session's TODO list.

## Overview

This tool retrieves the active TODO list for the current session, showing all tasks with their status, priority, and other metadata. Helps agents track progress and stay organized.

## Parameters

No parameters required - reads the current session's TODO list.

## Behavior

- Loads TODO list from `.moonagent/todos/current_session.json`
- Returns all tasks with their current status
- Shows priority levels and notes
- Provides formatted display with status emojis

## TODO Information

Each TODO item includes:
- **id**: Unique identifier
- **content**: Task description
- **status**: Pending, InProgress, or Completed
- **priority**: High, Medium, or Low
- **notes**: Optional additional context
- **created_at**: Creation timestamp
- **updated_at**: Last modification timestamp

## Display Format

Shows tasks with status emojis:
- ✅ Completed
- 🔄 In Progress
- ⏳ Pending

## Use Cases

- Tracking task progress
- Reviewing session goals
- Understanding current work status
- Planning next steps
- Showing thoroughness and organization
- Demonstrating progress to users

## Notes

- Part of the maria AI agent tool system
- Persists across agent interactions
- Stored in `.moonagent/todos/` directory
- Use proactively to stay organized
- Shows all tasks regardless of status
