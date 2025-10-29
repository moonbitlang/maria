///|
pub fn List::todos(self : List) -> Array[Item] {
  self.items.todos.copy()
}

fn Item::new(
  clock~ : String,
  content~ : String,
  id~ : String,
  notes? : String,
  priority~ : Priority,
  status~ : Status,
) -> Item {
  
  {
    content,
    created_at: clock,
    id,
    notes,
    priority,
    status,
    updated_at: clock,
  }
}
///|
// fn List::item(
//   self : List,
//   content : String,
//   status~ : Status,
//   priority~ : Priority,
//   notes? : String,
// ) -> Item raise {
//   let now = get_current_timestamp(self.clock)
//   {
//     content,
//     created_at: now,
//     id: self.uuid.v4().to_string()[0:8].to_string(),
//     notes,
//     priority,
//     status,
//     updated_at: now,
//   }
// }

///|
pub fn List::update_item(
  self : List,
  item : Item,
  content? : String,
  notes? : String?,
  status? : Status,
  priority? : Priority,
) -> Item raise {
  let mut updated = { ..item, updated_at: get_current_timestamp(self.clock) }
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
pub fn list(
  uuid~ : @uuid.Generator,
  clock? : &@clock.Clock = @clock.epoch,
  cwd~ : StringView,
) -> List raise {
  {
    uuid,
    clock,
    cwd: cwd.to_string(),
    items: {
      todos: [],
      created_at: get_current_timestamp(clock),
      updated_at: get_current_timestamp(clock),
    },
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
pub async fn List::load(self : List) -> Unit {
  let path = self.todo_file_path()
  guard @fs.exists(path) else {
    // TODO: document we skip it
    return
  }
  let content = @fs.read_file(path)
  let json = @json.parse(content)
  self.items = @json.from_json(json)
}

///|
pub async fn List::save(self : List) -> Unit {
  let todo_file_path = self.todo_file_path()
  @fs.make_directory(@path.dirname(todo_file_path), recursive=true)
  self.items.updated_at = get_current_timestamp(self.clock)
  let json : Json = self.items.to_json()
  @fs.write_to_file(todo_file_path, json.stringify(indent=2))
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
) -> Item raise {
  let content = match extract_task_tags(content) {
    [] => content
    [task, ..] => task
  }
  // let item = self.item(content, status~, priority~, notes?)
  let clock = get_current_timestamp(self.clock)
  let id = self.uuid.v4().to_string()[0:8].to_string()
  let item = Item::new(
    clock~,
    content=content,
    id~,
    notes?,
    priority~,
    status~,
  )
  self.items.todos.push(item)
  self.items.updated_at = get_current_timestamp(self.clock)
  item
}

///|
pub fn List::update_task(self : List, index : Index, item : Item) -> Unit raise {
  self.items.todos[index.0] = item
  self.items.updated_at = get_current_timestamp(self.clock)
}

///|
struct Index(Int)

///|
pub fn List::find(self : List, id : String) -> Index? {
  for i, todo in self.items.todos {
    if todo.id == id {
      return Some(Index(i))
    }
  }
  None
}

///|
pub fn List::get(self : List, index : Index) -> Item {
  self.items.todos[index.0]
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

fn Items::parse(content : String, priority~ : Priority, notes? : String, clock~ : String, id~ : String) -> Items {
  let todos: Array[Item] = []
  // First, try to parse <task> tags
  let task_matches = extract_task_tags(content)
  if task_matches.length() > 0 {
    // Found <task> tags, use them
    for task_content in task_matches {
      let trimmed = task_content.trim(char_set=" \t\r\n")
      if trimmed.length() > 0 {
        let todo = Item::new(
          clock~,
          content = trimmed.to_string(),
          id~,
          notes?,
          priority~,
          status = Pending,
        )
        todos.push(todo)
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
          clock~,
          content = clean_line,
          id~,
          notes?,
          priority~,
          status = Pending,
        )
        todos.push(todo)
      }
    }
  }
  {todos, created_at: clock, updated_at: clock}
}
///|
pub fn List::parse(
  self : List,
  content : String,
  priority~ : Priority,
  notes? : String,
) -> Unit raise {
  let clock = get_current_timestamp(self.clock)
  let id = self.uuid.v4().to_string()[0:8].to_string()
  self.items = Items::parse(content, priority~, notes?, clock~, id~)
  // let clock = get_current_timestamp(self.clock)
  // self.items.todos.clear()
  // self.items.created_at = clock
  // self.items.updated_at = self.items.created_at
  // // First, try to parse <task> tags
  // let task_matches = extract_task_tags(content)
  // if task_matches.length() > 0 {
  //   // Found <task> tags, use them
  //   for task_content in task_matches {
  //     let trimmed = task_content.trim(char_set=" \t\r\n")
  //     if trimmed.length() > 0 {
  //       let todo = Item::new(
  //         clock~,
  //         content = trimmed.to_string(),
  //         id = self.uuid.v4().to_string()[0:8].to_string(),
  //         notes?,
  //         priority~,
  //         status = Pending,
  //       )
  //       self.items.todos.push(todo)
  //     }
  //   }
  // } else {
  //   // Fallback to line-by-line parsing
  //   let lines = content.trim(char_set=" \t\r\n").split("\n")
  //   for line in lines {
  //     let trimmed_line = line.trim(char_set=" \t\r\n")
  //     if trimmed_line.length() == 0 {
  //       continue
  //     }

  //     // Remove common prefixes like "1.", "- ", "* ", etc.
  //     let clean_line = remove_list_prefixes(trimmed_line)
  //     if clean_line.length() > 0 {
  //       // let todo = self.item(clean_line, notes?, priority~, status=Pending)
  //       let todo = Item::new(
  //         clock~,
  //         content = clean_line,
  //         id = self.uuid.v4().to_string()[0:8].to_string(),
  //         notes?,
  //         priority~,
  //         status = Pending,
  //       )
  //       self.items.todos.push(todo)
  //     }
  //   }
  // }
}
