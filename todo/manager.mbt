///|
/// Get current ISO timestamp
fn get_current_timestamp() -> String raise {
  let tm = @uv.clock_gettime(Realtime)
  let zdt = @time.unix(tm.sec(), nanosecond=tm.nsec())
  zdt.to_string()
}

///|
pub struct Manager {
  cwd : StringView
  todos : Array[Item]
  mut created_at : String
  mut updated_at : String
}

///|
pub(all) enum Priority {
  High
  Medium
  Low
} derive(ToJson, @json.FromJson)

///|
pub(all) enum Status {
  Pending
  InProgress
  Completed
} derive(ToJson, @json.FromJson)

///|
pub struct Item {
  content : String
  created_at : String
  id : String
  notes : String?
  priority : Priority
  status : Status
  updated_at : String
} derive(ToJson, @json.FromJson)

///|
fn Item::new(
  content : String,
  status~ : Status,
  priority~ : Priority,
  notes? : String,
) -> Item raise {
  let now = get_current_timestamp()
  Item::{
    content,
    created_at: now,
    id: generate_todo_id(),
    notes,
    priority,
    status,
    updated_at: now,
  }
}

///|
pub fn Item::update(
  self : Item,
  content? : String,
  notes? : String?,
  status? : Status,
  priority? : Priority,
) -> Item raise {
  let mut updated = { ..self, updated_at: get_current_timestamp() }
  if content is Some(content) {
    updated = { ..updated, content, }
  }
  if notes is Some(notes) {
    updated = { ..updated, notes, }
  }
  if status is Some(status) {
    updated = { ..updated, status, }
  }
  if priority is Some(priority) {
    updated = { ..updated, priority, }
  }
  updated
}

///|
pub fn Manager::new(cwd~ : StringView) -> Manager raise {
  Manager::{
    cwd,
    todos: [],
    created_at: get_current_timestamp(),
    updated_at: get_current_timestamp(),
  }
}

///|
fn Manager::todo_file_path(self : Manager) -> StringView {
  return self.cwd
    |> @path.join(".moonagent")
    |> @path.join("todos")
    |> @path.join("current_session.json")
}

///|
pub async fn Manager::load(self : Manager) -> Unit {
  let path = self.todo_file_path()
  if !@fs.exists(path) {
    return
  }
  let content = @fs.read_file(path)
  let json = @json.parse(content)
  match json {
    {
      "created_at": String(created_at),
      "todos": todos,
      "updated_at": String(updated_at),
      ..
    } => {
      self.created_at = created_at
      let todos : Array[Item] = @json.from_json(todos)
      self.todos.append(todos)
      self.updated_at = updated_at
    }
    _ => println("Invalid todo file format at \{path.to_string()}")
  }
}

///|
/// Format todos for display with emojis and structure
pub fn Manager::display(self : Manager) -> String {
  if self.todos.length() == 0 {
    return "No todos found for this session."
  }
  let output = []
  output.push("=== Current Session Todo List ===\n")

  // Status emoji mapping
  fn get_status_emoji(status : Status) -> String {
    match status {
      Status::Completed => "✅"
      Status::InProgress => "🔄"
      Status::Pending => "⏳"
    }
  }

  // Priority icon mapping
  fn get_priority_icon(priority : Priority) -> String {
    match priority {
      Priority::High => "🔴"
      Priority::Medium => "🟡"
      Priority::Low => "🟢"
    }
  }

  // Display todos in a single list with status markers
  for i = 0; i < self.todos.length(); i = i + 1 {
    let todo = self.todos[i]
    let status_mark = get_status_emoji(todo.status)
    let priority_mark = get_priority_icon(todo.priority)

    // Format each todo item
    output.push(
      "\{i + 1}. \{status_mark} \{priority_mark} [\{todo.id}] \{todo.content}",
    )

    // Add notes if present
    match todo.notes {
      Some(notes) => output.push("   └─ 📝 \{notes}")
      None => ()
    }
  }
  output.push("")

  // Add summary statistics
  let total = self.todos.length()
  let mut pending_count = 0
  let mut in_progress_count = 0
  let mut completed_count = 0
  for todo in self.todos {
    match todo.status {
      Status::Pending => pending_count = pending_count + 1
      Status::InProgress => in_progress_count = in_progress_count + 1
      Status::Completed => completed_count = completed_count + 1
    }
  }
  let summary_parts = ["Total: \{total}"]
  if completed_count > 0 {
    summary_parts.push("✅ Completed: \{completed_count}")
  }
  if in_progress_count > 0 {
    summary_parts.push("🔄 In Progress: \{in_progress_count}")
  }
  if pending_count > 0 {
    summary_parts.push("⏳ Pending: \{pending_count}")
  }
  output.push("📊 Summary: " + summary_parts.join(" | "))
  output.join("\n")
}

///|
/// Extract content from <task> tags (simplified implementation)
fn extract_task_tags(content : String) -> Array[String] {
  let tasks = []
  let mut task = None
  loop content.view() {
    [.. "<task>", .. rest] => {
      task = Some(StringBuilder::new())
      continue rest
    }
    [.. "</task>", .. rest] => {
      if task is Some(t) {
        tasks.push(t.to_string())
        task = None
      }
      continue rest
    }
    [c, .. rest] => {
      if task is Some(t) {
        t.write_char(c)
      }
      continue rest
    }
    [] => break
  }
  tasks
}

///|
test "extract_task_tags" {
  @json.inspect(
    extract_task_tags(
      "This is a test.\n<task>First task</task>\nSome text.\n<task>Second task</task>\nEnd.",
    ),
    content=["First task", "Second task"],
  )
}

///|
pub fn Manager::add_task(
  self : Manager,
  content : String,
  status? : Status = Pending,
  priority? : Priority = Medium,
  notes? : String? = None,
) -> Item raise {
  let content = match extract_task_tags(content) {
    [] => content
    [task, ..] => task
  }
  let item = Item::new(content, status~, priority~, notes?)
  self.todos.push(item)
  self.updated_at = get_current_timestamp()
  item
}

///|
pub fn Manager::update_task(
  self : Manager,
  index : Index,
  item : Item,
) -> Unit raise {
  self.todos[index.0] = item
  self.updated_at = get_current_timestamp()
}

///|
fn generate_todo_id() -> String raise {
  @uuid.v4().to_string()[0:8].to_string()
}

///|
struct Index(Int)

///|
pub fn Manager::find(self : Manager, id : String) -> Index? {
  for i, todo in self.todos {
    if todo.id == id {
      return Some(Index(i))
    }
  }
  None
}

///|
pub fn Manager::get(self : Manager, index : Index) -> Item {
  self.todos[index.0]
}

///|
pub async fn save(self : Manager) -> Unit raise {
  let todo_file_path = self.todo_file_path()
  @fs.make_directory(@path.dirname(todo_file_path), recursive=true)
  self.updated_at = get_current_timestamp()
  let json : Json = {
    "created_at": self.created_at,
    "todos": self.todos,
    "updated_at": self.updated_at,
  }
  @fs.write_to_file(todo_file_path, json.stringify(indent=2))
}

///|
/// Remove common list prefixes from a line
fn remove_list_prefixes(line : String) -> String {
  let mut result = line

  // Remove numbered list prefixes like "1. ", "2. ", etc.
  if result.has_prefix("1.") ||
    result.has_prefix("2.") ||
    result.has_prefix("3.") ||
    result.has_prefix("4.") ||
    result.has_prefix("5.") ||
    result.has_prefix("6.") ||
    result.has_prefix("7.") ||
    result.has_prefix("8.") ||
    result.has_prefix("9.") {
    let mut i = 0
    while i < result.length() && result[i] >= '0' && result[i] <= '9' {
      i = i + 1
    }
    if i < result.length() && result[i] == '.' {
      i = i + 1
      while i < result.length() && result[i] == ' ' {
        i = i + 1
      }
      try {
        result = result[i:].to_string()
      } catch {
        _ => result = result
      }
    }
  }

  // Remove bullet prefixes like "- " and "* "
  if result.has_prefix("- ") {
    try {
      result = result[2:].to_string()
    } catch {
      _ => result = result
    }
  } else if result.has_prefix("* ") {
    try {
      result = result[2:].to_string()
    } catch {
      _ => result = result
    }
  }
  result.trim(" \t\r\n").to_string()
}

///|
pub fn Manager::parse(
  self : Manager,
  content : String,
  priority~ : Priority,
  notes? : String,
) -> Unit raise {
  self.todos.clear()
  self.created_at = get_current_timestamp()
  self.updated_at = self.created_at
  // First, try to parse <task> tags
  let task_matches = extract_task_tags(content)
  if task_matches.length() > 0 {
    // Found <task> tags, use them
    for task_content in task_matches {
      let trimmed = task_content.trim(" \t\r\n").to_string()
      if trimmed.length() > 0 {
        let todo = Item::new(trimmed, notes?, priority~, status=Pending)
        self.todos.push(todo)
      }
    }
  } else {
    // Fallback to line-by-line parsing
    let lines = content.trim(" \t\r\n").to_string().split("\n")
    for line in lines {
      let trimmed_line = line.trim(" \t\r\n").to_string()
      if trimmed_line.length() == 0 {
        continue
      }

      // Remove common prefixes like "1.", "- ", "* ", etc.
      let clean_line = remove_list_prefixes(trimmed_line)
      if clean_line.length() > 0 {
        let todo = Item::new(clean_line, notes?, priority~, status=Pending)
        self.todos.push(todo)
      }
    }
  }
}
