///|
priv struct HistoryManager {
  history : @deque.Deque[BytesView]
  mut index : Int
  size : Int
  events : @aqueue.Queue[@deque.Deque[BytesView]]
}

///|
fn HistoryManager::new(size : Int) -> HistoryManager {
  HistoryManager::{
    history: @deque.new(),
    index: -1,
    size,
    events: @aqueue.Queue::new(),
  }
}

///|
fn HistoryManager::can_navigate_to_next(self : HistoryManager) -> Bool {
  self.index > -1 && self.history.length() > 0
}

///|
fn HistoryManager::can_navigate_to_prev(self : HistoryManager) -> Bool {
  self.index < self.history.length() - 1
}

///|
fn BytesView::has_prefix(self : BytesView, prefix : BytesView) -> Bool {
  if self.length() <= prefix.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if self[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn BytesView::trim_start(self : BytesView) -> BytesView {
  loop self {
    [' ', .. rest] => continue rest
    [.. rest] => break rest
  }
}

///|
fn BytesView::trim_end(self : BytesView) -> BytesView {
  loop self {
    [.. rest, ' '] => continue rest
    [.. rest] => break rest
  }
}

///|
fn BytesView::trim(self : BytesView) -> BytesView {
  self.trim_start().trim_end()
}

///|
fn reverse_string(
  line : BytesView,
  from? : Byte = '\r',
  to? : Byte = '\r',
) -> BytesView {
  let parts = []
  let mut start = 0
  loop line[:] {
    [] => {
      parts.push(line[start:])
      break
    }
    [c, .. rest] as view if c == from => {
      parts.push(line[:view.start_offset()])
      start = rest.start_offset()
      continue rest
    }
    [_, .. rest] => continue rest
  }
  let buffer = @buffer.new()
  for i = parts.length() - 1; i > 0; i = i - 1 {
    buffer.write_bytesview(parts[i])
    buffer.write_byte(to)
  }
  buffer.write_bytesview(parts[0])
  return buffer.to_bytes()
}

///|
fn HistoryManager::add_history(
  self : HistoryManager,
  line : BytesView,
  is_multiline~ : Bool,
  last_command_errored~ : Bool,
) -> BytesView {
  if line.length() == 0 {
    return ""
  }
  if self.size == 0 {
    return line
  }
  if line.trim().length() == 0 {
    return line
  }
  if is_multiline && self.index == -1 {
    self.history.pop_back() |> ignore()
  } else if last_command_errored {
    self.history.pop_back() |> ignore()
  }
  let normalized_line = reverse_string(line, from='\n', to='\r')
  if self.history.length() == 0 || self.history.back() != Some(normalized_line) {
    // if self.remove_history_duplicates {
    //   for i, entry in self.history {
    //     if entry == normalized_line {
    //       self.history.remove(i) |> ignore()
    //       break
    //     }
    //   }
    // }
    self.history.push_back(normalized_line) |> ignore()
    if self.history.length() > self.size {
      self.history.pop_front() |> ignore()
    }
  }
  self.index = -1
  let final_line = if is_multiline {
    reverse_string(self.history.back().unwrap())
  } else {
    self.history.back().unwrap()
  }
  if self.events is history {
    history.put(self.history)
  }
  return final_line
}

///|
fn HistoryManager::navigate_to_next(
  self : HistoryManager,
  substring_search : BytesView,
) -> BytesView? {
  if !self.can_navigate_to_next() {
    return None
  }
  let search = substring_search
  let mut index = self.index - 1
  while index >= 0 && self.history[index].has_prefix(search) {
    index -= 1
  }
  self.index = index
  if index == -1 {
    return Some(search)
  }
  return Some(self.history[index])
}

///|
fn HistoryManager::navigate_to_previous(
  self : HistoryManager,
  substring_search : BytesView,
) -> BytesView? {
  if !self.can_navigate_to_prev() {
    return None
  }
  let search = substring_search
  let mut index = self.index + 1
  while index < self.history.length() && self.history[index].has_prefix(search) {
    index += 1
  }
  self.index = index
  if index == self.history.length() {
    return Some(search)
  }
  return Some(self.history[index])
}
