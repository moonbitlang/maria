///|
pub fn List::todos(self : List) -> Array[Item] {
  self.items.todos.copy()
}

///|
fn Config::uuid(self : Config) -> String {
  self.uuid.v4().to_string()[0:8].to_string() catch {
    err => "UUID error: \{err}"
  }
}

///|
fn Item::new(
  content~ : String,
  notes? : String,
  priority~ : Priority,
  status~ : Status,
  // config : Config,
  created_at~ : String,
  id~ : String,
) -> Item {
  let now = created_at
  let id = id
  { content, created_at: now, id, notes, priority, status, updated_at: now }
}

///|
fn Config::now(self : Config) -> String {
  self.clock.now_str()
}

///|
pub fn Item::update(
  self : Item,
  content? : String,
  notes? : String?,
  status? : Status,
  priority? : Priority,
  updated_at~ : String,
) -> Item {
  {
    ..self // id and some other fields remain the same
    ,
    content: content.unwrap_or(self.content),
    notes: notes.unwrap_or(self.notes),
    status: status.unwrap_or(self.status),
    priority: priority.unwrap_or(self.priority),
    updated_at,
  }
}

///|
pub fn List::now(self : List) -> String {
  self.config.now()
}

///|
pub fn List::uuid(self : List) -> String {
  self.config.uuid()
}

///|
pub fn list(
  uuid~ : @uuid.Generator,
  clock? : &@clock.Clock = @clock.epoch,
  cwd~ : StringView,
) -> List {
  {
    config: { uuid, clock, cwd: cwd.to_string() },
    items: {
      todos: [],
      created_at: clock.now_str(),
      updated_at: clock.now_str(),
    },
  }
}

///|
fn Config::todo_file_path(self : Config) -> String {
  return self.cwd
    |> @path.join(".moonagent")
    |> @path.join("todos")
    |> @path.join("current_session.json")
}

///|
pub async fn List::load(self : List) -> Unit {
  let path = self.config.todo_file_path()
  guard @fs.exists(path) else {
    // TODO: document we skip it
    return
  }
  self.items = @json.from_json(@json.parse(@fs.read_file(path)))
}

///|
pub async fn List::save(self : List) -> Unit {
  let todo_file_path = self.config.todo_file_path()
  @fs.make_directory(@path.dirname(todo_file_path), recursive=true)
  self.items.updated_at = self.config.now()
  @fs.write_to_file(todo_file_path, self.items.to_json().stringify(indent=2))
}

///|
/// Extract content from <task> tags (simplified implementation)
fn extract_task_tags(content : String) -> Array[String] {
  let tasks = []
  let mut task = None
  loop content[:] {
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
  let tasks =
    #|This is a test.
    #|<task>First task</task>
    #|Some text.
    #|<task>Second task</task>
    #|End.
  @json.inspect(extract_task_tags(tasks), content=["First task", "Second task"])
}

///|
pub fn List::add_task(
  self : List,
  content : String,
  status? : Status = Pending,
  priority? : Priority = Medium,
  notes? : String? = None,
) -> Item {
  let content = match extract_task_tags(content) {
    [] => content
    [task, ..] => task
  }
  let item = Item::new(
    content~,
    notes?,
    priority~,
    status~,
    created_at=self.now(),
    id=self.config.uuid(),
  )
  self.items.todos.push(item)
  self.items.updated_at = self.now()
  item
}

///|
pub fn List::update_task(self : List, index : Int, item : Item) -> Unit {
  self.items.todos[index] = item
  self.items.updated_at = self.config.now()
}

///|
pub fn List::find(self : List, id : String) -> Int? {
  for i, todo in self.items.todos {
    if todo.id == id {
      return Some(i)
    }
  }
  None
}

///|
pub fn List::get(self : List, index : Int) -> Item {
  self.items.todos[index]
}

///|
/// Remove common list prefixes from a line
fn remove_list_prefixes(line : StringView) -> String {
  let result = lexmatch line with longest {
      ("[0-9]+.\w*", rest) => rest
      ("-\w*", rest) => rest
      ("\*\w*", rest) => rest
      _ => line
    }
  result.trim(char_set=" \t\r\n").to_string()
}

///|
test "remove_list_prefixes" {
  @json.inspect(
    remove_list_prefixes("12   First task   "),
    content="First task",
  )
  @json.inspect(
    remove_list_prefixes("    12   First task   "),
    content="12   First task",
  )
  @json.inspect(remove_list_prefixes("1.   First task"), content="First task")
  @json.inspect(remove_list_prefixes("2.   Second task"), content="Second task")
  @json.inspect(remove_list_prefixes("- Bullet point"), content="Bullet point")
  @json.inspect(
    remove_list_prefixes("* Another bullet"),
    content="Another bullet",
  )
  @json.inspect(
    remove_list_prefixes("No prefix here"),
    content="No prefix here",
  )
}

///|
fn Items::parse(
  content : String,
  priority~ : Priority,
  notes? : String,
  config~ : Config,
) -> Items {
  let now = config.now()
  let items = Items::{ todos: [], created_at: now, updated_at: now }
  // First, try to parse <task> tags
  let task_matches = extract_task_tags(content)
  if task_matches.length() > 0 {
    // Found <task> tags, use them
    for task_content in task_matches {
      let trimmed = task_content.trim(char_set=" \t\r\n")
      if trimmed.length() > 0 {
        let todo = Item::new(
          content=trimmed.to_string(),
          notes?,
          priority~,
          status=Pending,
          created_at=config.now(),
          id=config.uuid(),
        )
        items.todos.push(todo)
      }
    }
  } else {
    // Fallback to line-by-line parsing
    let lines = content.trim(char_set=" \t\r\n").split("\n")
    for line in lines {
      let trimmed_line = line.trim(char_set=" \t\r\n")
      if trimmed_line.length() == 0 {
        continue
      }

      // Remove common prefixes like "1.", "- ", "* ", etc.
      let clean_line = remove_list_prefixes(trimmed_line)
      if clean_line.length() > 0 {
        let todo = Item::new(
          content=clean_line,
          notes?,
          priority~,
          status=Pending,
          // self.config,
          created_at=config.now(),
          id=config.uuid(),
        )
        items.todos.push(todo)
      }
    }
  }
  items
}

///|
pub fn List::parse(
  self : List,
  content : String,
  priority~ : Priority,
  notes? : String,
) -> Unit {
  self.items = Items::parse(content, priority~, notes?, config=self.config)
}
