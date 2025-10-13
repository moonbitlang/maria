# `moonbitlang/maria/tool/todo_write`

Creates and manages TODO items for session tracking.

## Overview

This tool allows AI agents to create, update, and manage TODO lists for tracking tasks and progress throughout a session. Essential for organized, multi-step workflows.

## Actions

### `create`
Creates a new TODO list from a description
- Parses tasks from text or `<task>` tags
- Sets priority level for all tasks
- Initializes the session TODO list

### `add_task`
Adds a single task to the existing list
- Appends to current TODO list
- Allows setting status, priority, and notes

### `update`
Updates an existing task
- Modifies content, status, priority, or notes
- Requires task ID

### `mark_progress`
Marks a task as "in progress"
- Updates status without changing other fields

### `mark_completed`
Marks a task as completed
- Updates status to "Completed"

## Parameters

Vary by action:
- `action` (required): Operation to perform
- `content`: Task description(s)
- `task_id`: For updates to specific tasks
- `priority`: High, Medium, or Low
- `status`: Pending, InProgress, or Completed
- `notes`: Optional additional context

## Task Parsing

Supports multiple formats:
- `<task>content</task>` tags (preferred)
- Numbered lists: `1. task`, `2. task`
- Bullet lists: `- task`, `* task`
- Plain text lines

## Use Cases

- Breaking down complex problems into steps
- Tracking progress on multi-part tasks
- Organizing work systematically
- Demonstrating thoroughness
- Planning and executing workflows
- Communicating progress to users

## Notes

- Part of the maria AI agent tool system
- Persists to `.moonagent/todos/current_session.json`
- Automatically saves after each operation
- Generates unique 8-character IDs for tasks
- Maintains timestamps for created_at and updated_at
