///|
#json.generated
fn Params::get_schema() -> Json {
  {
    "type": "object",
    "properties": {
      "action": {
        "type": "string",
        "description": "The action to perform: \n- 'create': create new todo list\n- 'add_task': add single task\n- 'update': update existing task\n- 'mark_progress': mark task as in progress\n- 'mark_completed': mark task as completed",
        "enum": [
          "create", "add_task", "update", "mark_progress", "mark_completed",
        ],
      },
      "content": {
        "type": "string",
        "description": "The task content or description (required for create, add_task actions). \nCan contain <task>...</task> tags for structured input.",
      },
      "task_id": {
        "type": "string",
        "description": "The ID of the task to update (required for update, mark_progress, mark_completed actions)",
      },
      "priority": {
        "type": "string",
        "description": "Task priority level: 'high', 'medium', 'low' (default: 'medium')",
        "default": "medium",
        "enum": ["high", "medium", "low"],
      },
      "status": {
        "type": "string",
        "description": "Task status: 'pending', 'in_progress', 'completed' (default: 'pending')",
        "default": "pending",
        "enum": ["pending", "in_progress", "completed"],
      },
      "notes": {
        "type": "string",
        "description": "Additional notes or details about the task",
      },
    },
    "required": ["action"],
  }
}
