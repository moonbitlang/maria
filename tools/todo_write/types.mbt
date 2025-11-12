///|
#json.schema
priv struct Params {
  /// The action to perform: 
  /// - 'create': create new todo list
  /// - 'add_task': add single task
  /// - 'update': update existing task
  /// - 'mark_progress': mark task as in progress
  /// - 'mark_completed': mark task as completed
  #json.enumerate(string("create", "add_task", "update", "mark_progress", "mark_completed"))
  action : String
  /// The task content or description (required for create, add_task actions). 
  /// Can contain <task>...</task> tags for structured input.
  content : String?
  /// The ID of the task to update (required for update, mark_progress, mark_completed actions)
  task_id : String?
  /// Task priority level: 'high', 'medium', 'low' (default: 'medium')
  #json.enumerate(string("high", "medium", "low"))
  #json.default(string("medium"))
  priority : String?
  /// Task status: 'pending', 'in_progress', 'completed' (default: 'pending')
  #json.enumerate(string("pending", "in_progress", "completed"))
  #json.default(string("pending"))
  status : String?
  /// Additional notes or details about the task
  notes : String?
} derive(ToJson)
