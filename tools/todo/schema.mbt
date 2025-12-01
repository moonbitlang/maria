///|
let todo_schema : @tool.JsonSchema = {
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "description": "The action to perform: 'read' (read current todo list), 'create' (create new todo list), 'add_task' (add single task), 'update' (update existing task), 'mark_progress' (mark task as in progress), 'mark_completed' (mark task as completed)",
    },
    "content": {
      "type": "string",
      "description": "The task content or description (required for create, add_task actions). Can contain <task>...</task> tags for structured input.",
    },
    "task_id": {
      "type": "string",
      "description": "The ID of the task to update (required for update, mark_progress, mark_completed actions)",
    },
    "priority": {
      "type": "string",
      "description": "Task priority level: 'high', 'medium', 'low' (default: 'medium')",
    },
    "status": {
      "type": "string",
      "description": "Task status: 'pending', 'in_progress', 'completed' (default: 'pending')",
    },
    "notes": {
      "type": "string",
      "description": "Additional notes or details about the task",
    },
  },
  "required": ["action"],
}
