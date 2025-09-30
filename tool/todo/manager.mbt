///|
/// Get current ISO timestamp
fn get_current_timestamp() -> String raise {
  @os.now().to_string()
}

///|
struct List {
  cwd : String
  mut todos : Array[Item]
  mut created_at : String
  mut updated_at : String
}

///|
pub(all) enum Priority {
  High
  Medium
  Low
} derive(ToJson)

///|
impl @json.FromJson for Priority with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Priority raise @json.JsonDecodeError {
  match json {
    "High" | "high" => High
    "Medium" | "medium" => Medium
    "Low" | "low" => Low
    _ =>
      raise @json.JsonDecodeError(
        (json_path, "Invalid Priority value: \{json}"),
      )
  }
}

///|
pub(all) enum Status {
  Pending
  InProgress
  Completed
} derive(ToJson)

///|
impl @json.FromJson for Status with from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> Status raise @json.JsonDecodeError {
  match json {
    "pending" | "Pending" => Pending
    "in_progress" | "InProgress" => InProgress
    "completed" | "Completed" => Completed
    _ =>
      raise @json.JsonDecodeError((json_path, "Invalid Status value: \{json}"))
  }
}

///|
pub(all) struct Item {
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
  id~ : String,
  content : String,
  status~ : Status,
  priority~ : Priority,
  notes? : String,
) -> Item raise {
  let now = get_current_timestamp()
  Item::{
    content,
    created_at: now,
    id,
    notes,
    priority,
    status,
    updated_at: now,
  }
}

///|
fn Item::update(
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
pub fn list(cwd~ : StringView) -> List raise {
  List::{
    cwd: cwd.to_string(),
    todos: [],
    created_at: get_current_timestamp(),
    updated_at: get_current_timestamp(),
  }
}

///|
fn List::todo_file_path(self : List) -> String {
  return self.cwd
    |> @path.join(".moonagent")
    |> @path.join("todos")
    |> @path.join("current_session.json")
}

///|
async fn List::load(self : List) -> Unit {
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
      self.todos = todos
      self.updated_at = updated_at
    }
    _ => println("Invalid todo file format at \{path.to_string()}")
  }
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
fn List::add_task(
  self : List,
  content : String,
  status? : Status = Pending,
  priority? : Priority = Medium,
  notes? : String? = None,
) -> Item raise {
  let content = match extract_task_tags(content) {
    [] => content
    [task, ..] => task
  }
  let item = Item::new(
    id=self.generate_todo_id(),
    content,
    status~,
    priority~,
    notes?,
  )
  self.todos.push(item)
  self.updated_at = get_current_timestamp()
  item
}

///|
fn List::update_task(self : List, index : Index, item : Item) -> Unit raise {
  self.todos[index.0] = item
  self.updated_at = get_current_timestamp()
}

///|
fn List::generate_todo_id(_ : List) -> String raise {
  @uuid.v4().to_string()[0:8].to_string()
}

///|
priv struct Index(Int)

///|
fn List::find(self : List, id : String) -> Index? {
  for i, todo in self.todos {
    if todo.id == id {
      return Some(Index(i))
    }
  }
  None
}

///|
fn List::get(self : List, index : Index) -> Item {
  self.todos[index.0]
}

///|
async fn save(self : List) -> Unit {
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
fn List::parse(
  self : List,
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
        let todo = Item::new(
          id=self.generate_todo_id(),
          trimmed,
          notes?,
          priority~,
          status=Pending,
        )
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
        let todo = Item::new(
          id=self.generate_todo_id(),
          clean_line,
          notes?,
          priority~,
          status=Pending,
        )
        self.todos.push(todo)
      }
    }
  }
}
