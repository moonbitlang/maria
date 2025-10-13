# `moonbitlang/maria/todo`

TODO list manager for tracking tasks with priorities and statuses.

## Overview

This package provides a comprehensive TODO list management system with support for task priorities, statuses, notes, and persistence to JSON files. Tasks can be parsed from text or `<task>` tags.

## Usage

### Creating a TODO List

```moonbit
let todos = @todo.list(cwd="/home/user/project")
let _ = todos
```

### Adding Tasks

```moonbit
let todos = @todo.list(cwd="/tmp")

let task = todos.add_task(
  "Implement feature X",
  status=@todo.Status::Pending,
  priority=@todo.Priority::High,
  notes="Needs review"
)

task.content // "Implement feature X"
```

### Parsing Tasks from Text

```moonbit
let todos = @todo.list(cwd="/tmp")

// Parse from numbered list
todos.parse(
  "1. First task\n2. Second task\n3. Third task",
  priority=@todo.Priority::Medium
)

todos.todos().length() // 3
```

### Parsing from Task Tags

```moonbit
let todos = @todo.list(cwd="/tmp")

todos.parse(
  "<task>Write tests</task>\nSome text\n<task>Update docs</task>",
  priority=@todo.Priority::Low
)

let tasks = todos.todos()
tasks.length() // 2
```

### Updating Tasks

```moonbit
let todos = @todo.list(cwd="/tmp")
let task = todos.add_task("Original task")

let updated = task.update(
  content="Updated task",
  status=@todo.Status::Completed,
  priority=@todo.Priority::High
)

let index = todos.find(task.id).unwrap()
todos.update_task(index, updated)
```

### Finding and Getting Tasks

```moonbit
let todos = @todo.list(cwd="/tmp")
let task = todos.add_task("Test task")

let index = todos.find(task.id)
match index {
  Some(idx) => {
    let found = todos.get(idx)
    found.content // "Test task"
  }
  None => ()
}
```

### Saving and Loading

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("todo-test")
  g.add_defer(() => dir.close())
  
  let todos = @todo.list(cwd=dir.path())
  todos.add_task("Task 1")
  todos.add_task("Task 2")
  
  todos.save()
  
  // Create new list and load
  let todos2 = @todo.list(cwd=dir.path())
  todos2.load()
  
  todos2.todos().length() // 2
})
```

## API Reference

### Types

#### `List`

A TODO list manager.

**Methods:**
- `todos() -> Array[Item]`: Returns a copy of all tasks
- `add_task(content: String, status?: Status, priority?: Priority, notes?: String?) -> Item raise`: Adds a new task
- `update_task(index: Index, item: Item) raise`: Updates a task at given index
- `find(id: String) -> Index?`: Finds a task by ID
- `get(index: Index) -> Item`: Gets a task at given index
- `parse(content: String, priority~: Priority, notes?: String) raise`: Parses tasks from text
- `save()`: Saves the list to `.moonagent/todos/current_session.json`
- `load()`: Loads the list from the JSON file

#### `Item`

A TODO item.

**Fields:**
- `content: String`: Task description
- `created_at: String`: ISO timestamp
- `id: String`: Unique 8-character ID
- `notes: String?`: Optional notes
- `priority: Priority`: Task priority
- `status: Status`: Task status
- `updated_at: String`: ISO timestamp

**Methods:**
- `update(content?: String, notes?: String?, status?: Status, priority?: Priority) -> Item raise`: Creates updated copy

#### `Priority`

Task priority levels.

- `High`: High priority
- `Medium`: Medium priority
- `Low`: Low priority

#### `Status`

Task completion status.

- `Pending`: Not started
- `InProgress`: Currently working on
- `Completed`: Finished

### Functions

#### `list(cwd~: StringView) -> List raise`

Creates a new TODO list for the given working directory.

## Parsing Behavior

The parser supports multiple formats:

1. **Task Tags**: `<task>content</task>` - Preferred format
2. **Numbered Lists**: `1. task`, `2. task`
3. **Bullet Lists**: `- task`, `* task`
4. **Plain Lines**: Each non-empty line becomes a task

Prefixes are automatically stripped, and empty lines are ignored.

## Storage

- Tasks are stored in `.moonagent/todos/current_session.json`
- Format includes metadata: `created_at`, `updated_at`, and `todos` array
- Automatic directory creation on save
- Timestamps use ISO format

## Notes

- Task IDs are unique 8-character UUIDs
- Timestamps are automatically managed
- Parse operations clear existing tasks
- Task tags take precedence over line-by-line parsing
- All operations maintain updated_at timestamps
