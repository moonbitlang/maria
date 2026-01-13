///|
priv struct Edit {
  text : BytesView
  cursor : Int
}

///|
/// Parsed key identity from terminal input.
/// Printable bytes are represented as `Byte(_)`, control keys use named variants.
pub enum KeyName {
  Escape
  Enter
  Return
  Backspace
  Delete
  Up
  Down
  Left
  Right
  Home
  End
  Insert
  Clear
  PageUp
  PageDown
  Tab
  F1
  F2
  F3
  F4
  F5
  F6
  F7
  F8
  F9
  F10
  F11
  F12
  PasteStart
  PasteEnd
  Space
  Byte(Byte)
  Undefined
}

///|
/// Normalized keypress info.
/// `sequence` holds the raw bytes read from the terminal for this keypress.
pub struct Key {
  mut meta : Bool
  mut name : KeyName
  mut sequence : Bytes
  mut ctrl : Bool
  mut shift : Bool
}

///|
priv struct Events {
  line : @aqueue.Queue[BytesView]
  keypress : @aqueue.Queue[KeyPress]
  key : @aqueue.Queue[Key]
}

///|
fn Events::new() -> Events {
  Events::{
    line: @aqueue.Queue::new(kind=Unbounded),
    keypress: @aqueue.Queue::new(kind=Unbounded),
    key: @aqueue.Queue::new(kind=Unbounded),
  }
}

///|
struct Interface {
  input : @stdio.Input
  output : @stdio.Output
  mut line : BytesView
  mut previous_line : BytesView
  mut is_multiline : Bool
  mut prompt : Bytes
  mut old_prompt : Bytes
  tab_size : Int
  mut cursor : Int
  mut previous_cursor : Int
  mut previous_cursor_cols : Int
  mut prev_rows : Int
  mut previous_prev_rows : Int
  mut previous_key : Key?
  undo_stack : @deque.Deque[Edit]
  redo_stack : @deque.Deque[Edit]
  kill_ring : @deque.Deque[BytesView]
  mut kill_ring_cursor : Int
  mut yanking : Bool
  mut substring_search : BytesView?
  history : @deque.Deque[Bytes]
  mut history_index : Int
  events : Events
  history_manager : HistoryManager
  mut saw_return_at : UInt64
  last_command_errored : Bool
  crlf_delay : UInt64
  is_completion_enabled : Bool
  completer : (async (StringView) -> CompletionResult)?
}

///|
/// Create a readline interface bound to the given input/output streams.
/// Puts the input into raw mode and initializes internal state.
pub fn interface(
  input~ : @stdio.Input,
  output? : @stdio.Output = @stdio.stdout,
) -> Interface raise {
  @tty.set_raw_mode(input.fd())
  Interface::{
    line: "",
    input,
    output,
    prompt: "",
    old_prompt: "",
    tab_size: 4,
    cursor: 0,
    previous_cursor: 0,
    previous_cursor_cols: 0,
    is_multiline: false,
    prev_rows: 0,
    previous_prev_rows: 0,
    undo_stack: @deque.new(),
    redo_stack: @deque.new(),
    kill_ring: @deque.new(),
    kill_ring_cursor: 0,
    yanking: false,
    substring_search: None,
    history: @deque.new(),
    history_index: -1,
    previous_key: None,
    events: Events::new(),
    history_manager: HistoryManager::new(1000),
    saw_return_at: 0,
    previous_line: "",
    last_command_errored: false,
    crlf_delay: 500,
    is_completion_enabled: false,
    completer: None,
  }
}

///|
/// Close the interface.
/// Currently a no-op placeholder.
pub fn Interface::close(_ : Interface) -> Unit {

}

///|
/// Replace the current line buffer and update multiline state.
pub fn Interface::set_line(self : Interface, line : BytesView) -> Unit {
  self.line = line
  loop line[:] {
    [] => break
    ['\n', ..] => {
      self.is_multiline = true
      break
    }
    [_, .. rest] => continue rest
  }
}

///|
async fn Interface::write_move_cursor(
  self : Interface,
  dx : Int,
  dy : Int,
) -> Unit {
  let buffer = @buffer.new()
  if dx < 0 {
    buffer.write_byte(@csi.Escape)
    buffer.write_byte('[')
    buffer.write_bytes(@encoding/utf8.encode((-dx).to_string()))
    buffer.write_byte('D')
  } else if dx > 0 {
    buffer.write_byte(@csi.Escape)
    buffer.write_byte('[')
    buffer.write_bytes(@encoding/utf8.encode(dx.to_string()))
    buffer.write_byte('C')
  }
  if dy < 0 {
    buffer.write_byte(@csi.Escape)
    buffer.write_byte('[')
    buffer.write_bytes(@encoding/utf8.encode((-dy).to_string()))
    buffer.write_byte('A')
  } else if dy > 0 {
    buffer.write_byte(@csi.Escape)
    buffer.write_byte('[')
    buffer.write_bytes(@encoding/utf8.encode(dy.to_string()))
    buffer.write_byte('B')
  }
  self.output.write(buffer.to_bytes())
}

///|
async fn @stdio.Output::cursor_to(
  self : @stdio.Output,
  col~ : Int,
  row? : Int,
) -> Unit {
  match row {
    None => {
      let buffer = @buffer.new()
      buffer.write_byte(@csi.Escape)
      buffer.write_byte('[')
      buffer.write_bytes(@encoding/utf8.encode((col + 1).to_string()))
      buffer.write_byte('G')
      self.write(buffer.to_bytes())
    }
    Some(row) => {
      let buffer = @buffer.new()
      buffer.write_byte(@csi.Escape)
      buffer.write_byte('[')
      buffer.write_bytes(@encoding/utf8.encode((row + 1).to_string()))
      buffer.write_byte(';')
      buffer.write_bytes(@encoding/utf8.encode((col + 1).to_string()))
      buffer.write_byte('H')
      self.write(buffer.to_bytes())
    }
  }
}

///|
async fn @stdio.Output::clear_screen_down(self : @stdio.Output) -> Unit {
  self.write(@csi.ClearScreenDown)
}

///|
async fn Interface::refresh_line(self : Interface) -> Unit {
  let line : Bytes = [..self.prompt, ..self.line]
  let display_pos = self.get_display_position(line)
  let line_cols = display_pos.cols
  let line_rows = display_pos.rows
  let cursor_pos = self.get_cursor_pos()
  let prev_rows = self.prev_rows
  if prev_rows > 0 {
    self.write_move_cursor(0, -prev_rows)
  }
  self.output.cursor_to(col=0)
  self.output.clear_screen_down()
  if self.is_multiline {
    let lines = []
    loop self.line[:] {
      ['\n', .. rest] as view => {
        lines.push(self.line[:view.start_offset()])
        continue rest
      }
      [_, .. rest] => continue rest
      [] => {
        lines.push(self.line)
        break
      }
    }
    self.output.write(self.prompt)
    self.output.write(lines[0])
    for line in lines[1:] {
      self.output.write("\n| ")
      self.output.write(line)
    }
  } else {
    self.output.write(line)
  }
  if line_cols == 0 {
    self.output.write(" ")
  }
  self.output.cursor_to(col=cursor_pos.cols)
  let diff = line_rows - cursor_pos.rows
  if diff > 0 {
    self.write_move_cursor(0, -diff)
  }
  self.prev_rows = cursor_pos.rows
}

///|
priv struct Position {
  cols : Int
  rows : Int
}

///|
fn Interface::columns(_ : Interface) -> Int raise {
  @tty.window_size().col
}

///|
const MultilinePrompt = "| "

///|
fn display_position(
  str : Bytes,
  col~ : Int,
  is_multiline~ : Bool,
  tab_size~ : Int,
) -> Position {
  let mut offset = 0
  let mut rows = 0
  loop str[:] {
    [] => break
    ['\n', .. rest] => {
      rows += (offset + col - 1) / col
      offset = if is_multiline { MultilinePrompt.length() } else { 0 }
      continue rest
    }
    ['\t', .. rest] => {
      offset += tab_size - offset % tab_size
      continue rest
    }
    [0x00..=0x7F, .. rest] => {
      offset += 1
      continue rest
    }
    [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let char = (((b0 & 0x1F) << 6) | (b1 & 0x3F)).unsafe_to_char()
      offset += @unicode/width.char(char).unwrap_or(1)
      continue rest
    }
    [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
    | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let b2 = b2.to_int()
      let char = (((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)).unsafe_to_char()
      offset += @unicode/width.char(char).unwrap_or(1)
      continue rest
    }
    [
      0xF0 as b0,
      0x90..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF4 as b0,
      0x80..=0x8F as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let b2 = b2.to_int()
      let b3 = b3.to_int()
      let char = (((b0 & 0x07) << 18) |
      ((b1 & 0x3F) << 12) |
      ((b2 & 0x3F) << 6) |
      (b3 & 0x3F)).unsafe_to_char()
      offset += @unicode/width.char(char).unwrap_or(1)
      continue rest
    }
    [_, .. rest] => {
      offset += 1
      continue rest
    }
  }
  let cols = offset % col
  rows += offset / col
  { cols, rows }
}

///|
fn Interface::get_cursor_pos(self : Interface) -> Position raise {
  let string_before_cursor = @buffer.new()
  string_before_cursor.write_bytes(self.prompt)
  string_before_cursor.write_bytesview(self.line[:self.cursor])
  self.get_display_position(string_before_cursor.to_bytes())
}

///|
async fn Interface::move_cursor(self : Interface, dx : Int) -> Unit {
  if dx == 0 {
    return
  }
  let old_pos = self.get_cursor_pos()
  self.cursor += dx
  if self.cursor < 0 {
    self.cursor = 0
  } else if self.cursor > self.line.length() {
    self.cursor = self.line.length()
  }
  let new_pos = self.get_cursor_pos()
  if old_pos.rows == new_pos.rows {
    let diff_width = new_pos.cols - old_pos.cols
    self.write_move_cursor(diff_width, 0)
  } else {
    self.refresh_line()
  }
}

///|
fn Interface::get_display_position(
  self : Interface,
  str : Bytes,
) -> Position raise {
  display_position(
    str,
    col=self.columns(),
    is_multiline=self.is_multiline,
    tab_size=self.tab_size,
  )
}

///|
fn Interface::push_to_undo_stack(
  self : Interface,
  text : BytesView,
  cursor : Int,
) -> Unit {
  self.undo_stack.push_back({ text, cursor })
  if self.undo_stack.length() > 2048 {
    self.undo_stack.pop_front() |> ignore()
  }
}

///|
fn Interface::before_edit(
  self : Interface,
  old_text : BytesView,
  old_cursor : Int,
) -> Unit {
  self.push_to_undo_stack(old_text, old_cursor)
}

///|
async fn Interface::insert_string(self : Interface, string : BytesView) -> Unit {
  self.before_edit(self.line, self.cursor)
  if self.cursor < self.line.length() {
    let begin = self.line[:self.cursor]
    let end = self.line[self.cursor:]
    let buffer = @buffer.new()
    buffer.write_bytesview(begin)
    buffer.write_bytesview(string)
    buffer.write_bytesview(end)
    self.set_line(buffer.to_bytes())
    self.cursor += string.length()
    self.refresh_line()
  } else {
    let old_pos = self.get_cursor_pos()
    self.line = [..self.line, ..string]
    self.cursor = self.line.length()
    let new_pos = self.get_cursor_pos()
    if old_pos.rows == new_pos.rows {
      self.refresh_line()
    } else {
      self.output.write(string)
    }
  }
}

///|
async fn Interface::delete_line_left(self : Interface) -> Unit {
  self.before_edit(self.line, self.cursor)
  let del = self.line[:self.cursor]
  self.set_line(self.line[self.cursor:])
  self.cursor = 0
  self.push_to_kill_ring(del)
  self.refresh_line()
}

///|
async fn Interface::delete_line_right(self : Interface) -> Unit {
  self.before_edit(self.line, self.cursor)
  let del = self.line[self.cursor:]
  self.set_line(self.line[:self.cursor])
  self.push_to_kill_ring(del)
  self.refresh_line()
}

///|
const MaxLengthOfKillRing = 32

///|
fn Interface::push_to_kill_ring(
  self : Interface,
  del : BytesView,
) -> Unit noraise {
  if del == "" || self.kill_ring.back() == Some(del) {
    return
  }
  self.kill_ring.push_back(del)
  self.kill_ring_cursor = 0
  while self.kill_ring.length() > MaxLengthOfKillRing {
    self.kill_ring.pop_front() |> ignore()
  }
}

///|
async fn Interface::delete_left(self : Interface) -> Unit {
  if self.cursor > 0 && self.line.length() > 0 {
    self.before_edit(self.line, self.cursor)
    let char_size = @unicode.char_size_left(self.line, self.cursor)
    let buffer = @buffer.new()
    buffer.write_bytesview(self.line[:self.cursor - char_size])
    buffer.write_bytesview(self.line[self.cursor:])
    self.line = buffer.to_bytes()
    self.cursor -= char_size
    self.refresh_line()
  }
}

///|
async fn Interface::delete_right(self : Interface) -> Unit {
  if self.cursor < self.line.length() {
    self.before_edit(self.line, self.cursor)
    let char_size = @unicode.char_size_right(self.line, self.cursor)
    let buffer = @buffer.new()
    buffer.write_bytesview(self.line[:self.cursor])
    buffer.write_bytesview(self.line[self.cursor + char_size:])
    self.line = buffer.to_bytes()
    self.refresh_line()
  }
}

///|
/// Error raised when the user aborts input (for example Ctrl-C).
pub suberror Aborted {
  CtrlC
}

///|
async fn Interface::history_next(self : Interface) -> Unit {
  if !self.history_manager.can_navigate_to_next() {
    return
  }
  self.before_edit(self.line, self.cursor)
  self.set_line(
    self.history_manager
    .navigate_to_next(self.substring_search.unwrap_or(""))
    .unwrap_or(""),
  )
  self.cursor = self.line.length()
  self.refresh_line()
}

///|
async fn Interface::history_prev(self : Interface) -> Unit {
  if !self.history_manager.can_navigate_to_prev() {
    return
  }
  self.before_edit(self.line, self.cursor)
  self.set_line(
    self.history_manager
    .navigate_to_previous(self.substring_search.unwrap_or(""))
    .unwrap_or(""),
  )
  self.cursor = self.line.length()
  self.refresh_line()
}

///|
async fn Interface::yank(self : Interface) -> Unit {
  if self.kill_ring.length() > 0 {
    self.yanking = true
    self.insert_string(self.kill_ring[self.kill_ring_cursor])
  }
}

///|
async fn Interface::yank_pop(self : Interface) -> Unit {
  if self.yanking && self.kill_ring.length() > 1 {
    self.before_edit(self.line, self.cursor)
    let current = self.kill_ring[self.kill_ring_cursor]
    let buffer = @buffer.new()
    buffer.write_bytesview(self.line[:self.cursor - current.length()])
    self.kill_ring_cursor = (self.kill_ring_cursor + 1) %
      self.kill_ring.length()
    let next = self.kill_ring[self.kill_ring_cursor]
    buffer.write_bytesview(next)
    buffer.write_bytesview(self.line[self.cursor:])
    self.line = buffer.to_bytes()
    self.cursor = self.cursor - current.length() + next.length()
    self.refresh_line()
  }
}

///|
fn word_size_left(string : BytesView, index : Int) -> Int {
  if index == 0 {
    return 0
  }
  let reversed = string[:index]
    .to_bytes()
    .to_fixedarray()
    .rev()
    .unsafe_reinterpret_as_bytes()
  lexmatch reversed with longest {
    ("[[:space:]]*([^[:word:][:space:]]+|[[:word:]]+)", rest) => rest.length()
    _ => 1
  }
}

///|
fn word_right_left(string : BytesView, index : Int) -> Int {
  if index >= string.length() {
    return 0
  }
  let forward = string[index:]
    .to_bytes()
    .to_fixedarray()
    .unsafe_reinterpret_as_bytes()
  lexmatch forward with longest {
    ("([^[:word:][:space:]]+|[[:word:]]+)[[:space:]]*", rest) => rest.length()
    _ => 1
  }
}

///|
async fn Interface::delete_word_left(self : Interface) -> Unit {
  if self.cursor > 0 {
    self.before_edit(self.line, self.cursor)
    let leading = self.line[:self.cursor]
    let reversed = leading
      .to_bytes()
      .to_fixedarray()
      .rev()
      .unsafe_reinterpret_as_bytes()
    let buffer = @buffer.new()
    lexmatch reversed with longest {
      ("[[:space:]]*([^[:word:][:space:]]+|[[:word:]]+)", rest) =>
        buffer.write_bytesview(leading[:rest.length()])
      _ => buffer.write_bytesview(leading[:leading.length() - 1])
    }
    self.cursor = buffer.length()
    buffer.write_bytesview(self.line[self.cursor:])
    self.line = buffer.to_bytes()
    self.refresh_line()
  }
}

///|
async fn Interface::delete_word_right(self : Interface) -> Unit {
  if self.cursor < self.line.length() {
    self.before_edit(self.line, self.cursor)
    let trailing = self.line[self.cursor:]
    let buffer = @buffer.new()
    buffer.write_bytesview(self.line[:self.cursor])
    lexmatch trailing with longest {
      ("([^[:word:][:space:]]+|[[:word:]]+)[[:space:]]*", rest) =>
        buffer.write_bytesview(trailing[rest.length():])
      _ => buffer.write_bytesview(trailing[1:])
    }
    self.line = buffer.to_bytes()
    self.refresh_line()
  }
}

///|
async fn Interface::word_left(self : Interface) -> Unit {
  if self.cursor > 0 {
    let size = word_size_left(self.line, self.cursor)
    self.move_cursor(-size)
  }
}

///|
async fn Interface::word_right(self : Interface) -> Unit {
  if self.cursor < self.line.length() {
    let size = word_right_left(self.line, self.cursor)
    self.move_cursor(size)
  }
}

///|
/// Set the prompt bytes used for subsequent renders.
pub fn Interface::set_prompt(self : Interface, prompt : Bytes) -> Unit {
  self.prompt = prompt
}

///|
async fn Interface::undo(self : Interface) -> Unit {
  guard self.undo_stack.pop_back() is Some(edit) else { return }
  self.set_line(edit.text)
  self.cursor = edit.cursor
  self.refresh_line()
}

///|
async fn Interface::redo(self : Interface) -> Unit {
  guard self.redo_stack.pop_back() is Some(edit) else { return }
  self.set_line(edit.text)
  self.cursor = edit.cursor
  self.refresh_line()
}

///|
fn Interface::save_previous_state(self : Interface) -> Unit {
  self.previous_line = self.line
  self.previous_cursor = self.cursor
  self.previous_prev_rows = self.prev_rows
}

///|
fn Interface::restore_previous_state(self : Interface) -> Unit {
  self.set_line(self.previous_line)
  self.cursor = self.previous_cursor
  self.prev_rows = self.previous_prev_rows
}

///|
/// Insert a newline at the cursor and update the internal line buffer.
/// This is intended for use after restoring a previous UI state.
pub fn Interface::add_new_line_on_tty(self : Interface) -> Unit {
  self.restore_previous_state()
  let before_cursor = self.line[:self.cursor]
  let after_cursor = self.line[self.cursor:]
  self.set_line([..before_cursor, '\n', ..after_cursor])
  self.cursor += 1
}

///|
fn Interface::add_history(self : Interface) -> BytesView {
  return self.history_manager.add_history(
    self.line,
    is_multiline=self.is_multiline,
    last_command_errored=self.last_command_errored,
  )
}

///|
async fn Interface::clear_line(self : Interface) -> Unit {
  self.move_cursor(self.line.length() - self.cursor)
  self.output.write("\r\n")
  self.set_line("")
  self.cursor = 0
  self.prev_rows = 0
}

///|
async fn Interface::line(self : Interface) -> Unit {
  self.save_previous_state()
  let line = self.add_history()
  self.undo_stack.clear()
  self.redo_stack.clear()
  self.clear_line()
  self.events.line.put(line)
}

///|
fn BytesView::split(self : BytesView, sep : Byte) -> Array[BytesView] {
  let parts = []
  let mut start = 0
  loop self[:] {
    [] => {
      parts.push(self[start:])
      break
    }
    [b, .. rest] as view if b == sep => {
      parts.push(self[start:view.start_offset()])
      start = rest.start_offset()
      continue rest
    }
    [_, .. rest] => continue rest
  }
  return parts
}

///|
async fn Interface::multiline_move(
  self : Interface,
  direction : Int,
  split_lines : Array[BytesView],
  cursor_pos : Position,
) -> Unit {
  let rows = cursor_pos.rows
  let cols = cursor_pos.cols
  let curr = split_lines[rows]
  let down = direction == 1
  let adj = split_lines[rows + direction]
  let prompt_len = MultilinePrompt.length()
  let mut amount_to_move = 0
  let clamp = if down {
    curr.length() - cols + prompt_len + adj.length() + 1
  } else {
    -cols + 1
  }
  let should_clamp = cols > adj.length() + 1
  if should_clamp {
    if self.previous_cursor_cols == -1 {
      self.previous_cursor_cols = cols
    }
    amount_to_move = clamp
  } else {
    if down {
      amount_to_move = curr.length() + 1
    } else {
      amount_to_move = -adj.length() - 1
    }
    if self.previous_cursor_cols != -1 {
      if self.previous_cursor_cols < adj.length() {
        amount_to_move = self.previous_cursor_cols - cols
        self.previous_cursor_cols = -1
      } else {
        amount_to_move = clamp
      }
    }
  }
  self.move_cursor(amount_to_move)
}

///|
async fn Interface::move_up_or_history_prev(self : Interface) -> Unit {
  let cursor_pos = self.get_cursor_pos()
  if self.is_multiline && cursor_pos.rows > 0 {
    let split_lines = self.line.split('\n')
    self.multiline_move(-1, split_lines, cursor_pos)
    return
  }
  self.previous_cursor_cols = -1
  self.history_prev()
}

///|
async fn Interface::move_down_or_history_next(self : Interface) -> Unit {
  let cursor_pos = self.get_cursor_pos()
  let split_lines = self.line.split('\n')
  if self.is_multiline && cursor_pos.rows + 1 < split_lines.length() {
    self.multiline_move(1, split_lines, cursor_pos)
    return
  }
  self.previous_cursor_cols = -1
  self.history_next()
}

///|
priv suberror EOF

///|
async fn Interface::read_byte(self : Interface) -> Byte {
  match self.input.read_exactly(1) {
    [] => raise EOF
    [b] => return b
    _ => panic()
  }
}

///|
priv struct KeyPress {
  sequence : Bytes?
  key : Key
}

///|
async fn Interface::emit_keypress(self : Interface) -> Unit {
  let mut ch = self.read_byte()
  let s = @buffer.new()
  s.write_byte(ch)
  let mut escaped = false
  let key = Key::{
    meta: false,
    name: Undefined,
    ctrl: false,
    shift: false,
    sequence: "",
  }
  if ch is @csi.Escape {
    escaped = true
    ch = self.read_byte()
    s.write_byte(ch)
    if ch is @csi.Escape {
      ch = self.read_byte()
      s.write_byte(ch)
    }
  }
  if escaped && ch is ('O' | '[') {
    // ANSI escape sequence
    let code = @buffer.new()
    let mut modifier = 0
    if ch is 'O' {
      // ESC O letter
      // ESC O modifier letter
      ch = self.read_byte()
      s.write_byte(ch)
      if ch is ('0'..='9') {
        modifier = ch.to_int() - '0' - 1
        ch = self.read_byte()
        s.write_byte(ch)
      }
      code.write_byte(ch)
    } else if ch is '[' {
      // ESC [ sequences
      ch = self.read_byte()
      s.write_byte(ch)
      if ch is '[' {
        // Double bracket sequences like \x1b[[A
        code.write_byte(ch)
        ch = self.read_byte()
        s.write_byte(ch)
      }
      let cmd = @buffer.new()

      // Skip one or two leading digits
      if ch is ('0'..='9') {
        ch = self.read_byte()
        s.write_byte(ch)
        cmd.write_byte(ch)
        if ch is ('0'..='9') {
          ch = self.read_byte()
          s.write_byte(ch)
          cmd.write_byte(ch)
          if ch is ('0'..='9') {
            ch = self.read_byte()
            s.write_byte(ch)
            cmd.write_byte(ch)
          }
        }
      }

      // skip modifier
      if ch is ';' {
        ch = self.read_byte()
        s.write_byte(ch)
        cmd.write_byte(ch)
        if ch is ('0'..='9') {
          let ch = self.read_byte()
          s.write_byte(ch)
          cmd.write_byte(ch)
        }
      }
      let cmd = cmd.to_bytes()
      match cmd {
        // (\d\d?)(;(\d))?([~^$])
        [
          '0'..='9' as d0,
          '0'..='9' as d1,
          ';',
          '0'..='9' as m0,
          '~'
          | '^'
          | '$' as s0,
        ] => {
          code.write_byte(d0)
          code.write_byte(d1)
          code.write_byte(s0)
          modifier = m0.to_int() - '0' - 1
        }
        ['0'..='9' as d0, '0'..='9' as d1, '~' | '^' | '$' as s0] => {
          code.write_byte(d0)
          code.write_byte(d1)
          code.write_byte(s0)
          modifier = 0
        }
        ['0'..='9' as d0, ';', '0'..='9' as m0, '~' | '^' | '$' as s0] => {
          code.write_byte(d0)
          code.write_byte(s0)
          modifier = m0.to_int() - '0' - 1
        }
        ['0'..='9' as d0, '~' | '^' | '$' as s0] => {
          code.write_byte(d0)
          code.write_byte(s0)
          modifier = 0
        }
        // (\d{3}~)
        ['0'..='9', '0'..='9', '0'..='9', '~'] => code.write_bytesview(cmd)
        // ((\d;)?(\d))?([A-Za-z])
        ['0'..='9', ';', '0'..='9' as m0, 'a'..='z' | 'A'..='z' as c0]
        | ['0'..='9' as m0, 'a'..='z' | 'A'..='z' as c0] => {
          code.write_byte(c0)
          modifier = m0.to_int() - '0' - 1
        }
        ['a'..='z' | 'A'..='z' as c0] => {
          code.write_byte(c0)
          modifier = 0
        }
        _ => code.write_bytesview(cmd)
      }
    }

    // Parse the key modifier
    key.ctrl = (modifier & 4) != 0
    key.meta = (modifier & 10) != 0
    key.shift = (modifier & 1) != 0
    let code = code.to_bytes()
    match code {
      // xterm/gnome ESC [ letter (with modifier)
      "[P" => key.name = F1
      "[Q" => key.name = F2
      "[R" => key.name = F3
      "[S" => key.name = F4

      // xterm/gnome ESC O letter (without modifier)
      "OP" => key.name = F1
      "OQ" => key.name = F2
      "OR" => key.name = F3
      "OS" => key.name = F4

      // xterm/rxvt ESC [ number ~
      "[11~" => key.name = F1
      "[12~" => key.name = F2
      "[13~" => key.name = F3
      "[14~" => key.name = F4
      "[15~" => key.name = F5
      "[17~" => key.name = F6
      "[18~" => key.name = F7
      "[19~" => key.name = F8
      "[20~" => key.name = F9
      "[21~" => key.name = F10
      "[23~" => key.name = F11
      "[24~" => key.name = F12

      // paste bracket mode
      "[200~" => key.name = PasteStart
      "[201~" => key.name = PasteEnd

      // from Cygwin and used in libuv
      "[[A" => key.name = F1
      "[[B" => key.name = F2
      "[[C" => key.name = F3
      "[[D" => key.name = F4
      "[[E" => key.name = F5

      // xterm ESC [ letter
      "[A" => key.name = Up
      "[B" => key.name = Down
      "[C" => key.name = Right
      "[D" => key.name = Left
      "[E" => key.name = Clear
      "[F" => key.name = End
      "[H" => key.name = Home

      // xterm/gnome ESC O letter
      "OA" => key.name = Up
      "OB" => key.name = Down
      "OC" => key.name = Right
      "OD" => key.name = Left
      "OE" => key.name = Clear
      "OF" => key.name = End
      "OH" => key.name = Home

      // xterm/rxvt ESC [ number ~
      "[1~" => key.name = Home
      "[2~" => key.name = Insert
      "[3~" => key.name = Delete
      "[4~" => key.name = End
      "[5~" => key.name = PageUp
      "[6~" => key.name = PageDown
      "[7~" => key.name = Home
      "[8~" => key.name = End

      // putty
      "[[5~" => key.name = PageUp
      "[[6~" => key.name = PageDown

      // rxvt keys with modifiers
      "[a" => {
        key.shift = true
        key.name = Up
      }
      "[b" => {
        key.shift = true
        key.name = Down
      }
      "[c" => {
        key.shift = true
        key.name = Right
      }
      "[d" => {
        key.shift = true
        key.name = Left
      }
      "[e" => {
        key.shift = true
        key.name = Clear
      }
      "[2$" => {
        key.shift = true
        key.name = Insert
      }
      "[3$" => {
        key.shift = true
        key.name = Delete
      }
      "[5$" => {
        key.shift = true
        key.name = PageUp
      }
      "[6$" => {
        key.shift = true
        key.name = PageDown
      }
      "[7$" => {
        key.shift = true
        key.name = Home
      }
      "[8$" => {
        key.shift = true
        key.name = End
      }
      "Oa" => {
        key.ctrl = true
        key.name = Up
      }
      "Ob" => {
        key.ctrl = true
        key.name = Down
      }
      "Oc" => {
        key.ctrl = true
        key.name = Right
      }
      "Od" => {
        key.ctrl = true
        key.name = Left
      }
      "Oe" => {
        key.ctrl = true
        key.name = Clear
      }
      "[2^" => {
        key.ctrl = true
        key.name = Insert
      }
      "[3^" => {
        key.ctrl = true
        key.name = Delete
      }
      "[5^" => {
        key.ctrl = true
        key.name = PageUp
      }
      "[6^" => {
        key.ctrl = true
        key.name = PageDown
      }
      "[7^" => {
        key.ctrl = true
        key.name = Home
      }
      "[8^" => {
        key.ctrl = true
        key.name = End
      }

      // misc
      "[Z" => {
        key.shift = true
        key.name = Tab
      }
      _ => key.name = Undefined
    }
  } else {
    match ch {
      '\r' => {
        key.name = Return
        key.meta = escaped
      }
      '\n' => {
        key.name = Enter
        key.meta = escaped
      }
      '\t' => {
        key.name = Tab
        key.meta = escaped
      }
      '\b' | 0x7f => key.name = Backspace
      @csi.Escape => {
        key.name = Escape
        key.meta = escaped
      }
      ' ' => {
        key.name = Space
        key.meta = escaped
      }
      0x00..=0x1a if !escaped => {
        key.name = Byte((ch.to_int() + b'a'.to_int() - 1).to_byte())
        key.ctrl = true
      }
      'A'..='Z' => {
        key.name = Byte((ch.to_int() + b'a'.to_int() - b'A'.to_int()).to_byte())
        key.shift = true
        key.meta = escaped
      }
      '0'..='9' | 'a'..='z' => {
        key.name = Byte(ch)
        key.shift = false
        key.meta = escaped
      }
      _ =>
        if escaped {
          // Escape sequence timeout
          if s.length() != 0 {
            key.name = Undefined
          } else {
            key.name = Escape
          }
          key.meta = true
        }
    }
  }
  let s = s.to_bytes()
  key.sequence = s
  if s.length() != 0 && (!(key.name is Undefined) || escaped) {
    if escaped {
      self.events.keypress.put(KeyPress::{ sequence: None, key })
    } else {
      self.events.keypress.put(KeyPress::{ sequence: Some(s), key })
    }
  } else if s.length() == 1 {
    self.events.keypress.put(KeyPress::{ sequence: Some(s), key })
  }
}

///|
/// Completion results returned by a user-supplied completer.
/// `complete_on` is the prefix that should be replaced by the completion.
pub(all) struct CompletionResult {
  completions : Array[StringView]
  complete_on : StringView
}

///|
async fn Interface::tab_complete(
  self : Interface,
  last_keypress_was_tab~ : Bool,
) -> Unit {
  guard self.completer is Some(completer) else { return }
  let string = self.line[:self.cursor]
  try {
    let value = completer(@encoding/utf8.decode(string))
    self.tab_completer(last_keypress_was_tab~, value)
  } catch {
    error =>
      self.output.write(@encoding/utf8.encode("Tab completion error: \{error}"))
  }
}

///|
fn common_prefix(array : Array[StringView]) -> StringView {
  array.sort()
  match array {
    [] => ""
    [string] => string
    [min, .., max] => {
      let prefix = StringBuilder::new()
      loop (min, max) {
        ([min_c, .. min], [max_c, .. max]) if min_c == max_c => {
          prefix.write_char(min_c)
          continue (min, max)
        }
        _ => return prefix.to_string()
      }
    }
  }
}

///|
async fn Interface::tab_completer(
  self : Interface,
  last_keypress_was_tab~ : Bool,
  completion_result : CompletionResult,
) -> Unit {
  let completions = completion_result.completions
  let complete_on = @encoding/utf8.encode(completion_result.complete_on)
  if completions.length() == 0 {
    return
  }
  if completions.length() == 1 {
    let completion = @encoding/utf8.encode(completions[0])
    let suffix = completion[complete_on.length():]
    self.insert_string(suffix)
    return
  }
  let prefix = common_prefix(completions.filter(c => c.length() > 0))
  if prefix.length() > complete_on.length() {
    let suffix = prefix[complete_on.length():]
    self.insert_string(@encoding/utf8.encode(suffix))
    return
  }
  if !last_keypress_was_tab {
    return
  }
  self.before_edit(self.line, self.cursor)
  let completion_widths = completions.map(@unicode/width.string(_))
  let mut width = 0
  for completion_width in completion_widths {
    width = @cmp.maximum(width, completion_width)
  }
  width = width + 2
  let max_columns = @cmp.maximum(1, self.columns() / width)
  let output = @buffer.new()
  output.write_bytes("\r\n")
  let mut line_index = 0
  let mut whitespace = 0
  for i, completion in completions {
    if completion is "" || line_index == max_columns {
      output.write_bytes("\r\n")
      line_index = 0
      whitespace = 0
    } else {
      output.write_bytesview(Bytes::make(whitespace, ' '))
    }
    if completion.length() > 0 {
      output.write_bytes(@encoding/utf8.encode(completion))
      whitespace = width - completion_widths[i]
      line_index += 1
    } else {
      output.write_bytes("\r\n")
    }
  }
  if line_index != 0 {
    output.write_bytes("\r\n\r\n")
  }
  self.output.write(output.to_bytes())
  self.refresh_line()
}

///|
async fn Interface::handle_keypress(
  self : Interface,
  keypress : KeyPress,
) -> Unit {
  let key = keypress.key
  // FIXME: used for autocomplete
  let previous_key = self.previous_key
  self.previous_key = Some(key)
  let mut should_reset_previous_cursor_cols = true
  if !key.meta || !(key.name is Byte('y')) {
    self.yanking = false
  }
  if key.name is (Up | Down) && !key.ctrl && !key.meta && !key.shift {
    if self.substring_search is Some(_) {
      self.substring_search = None
      if self.history.length() == self.history_index {
        self.history_index = -1
      }
    } else if !self.is_multiline {
      self.substring_search = Some(self.line[:self.cursor])
    }
  }
  match key.sequence {
    [0x1f, ..] => self.undo()
    [0x1e, ..] => self.redo()
    _ => ()
  }
  if key.name is Escape {
    return
  }
  if key.ctrl && key.shift {
    match key.name {
      Backspace => self.delete_line_left()
      Delete => self.delete_line_right()
      _ => ()
    }
  } else if key.ctrl {
    match key.name {
      Byte('c') => raise Aborted::CtrlC
      Byte('h') => self.delete_left()
      Byte('d') =>
        if self.cursor == 0 && self.line.length() == 0 {
          raise EOF
        } else if self.cursor < self.line.length() {
          self.delete_right()
        }
      Byte('u') => self.delete_line_left()
      Byte('k') => self.delete_line_right()
      Byte('a') => self.move_cursor(-self.cursor)
      Byte('e') => self.move_cursor(self.line.length() - self.cursor)
      Byte('b') =>
        self.move_cursor(-@unicode.char_size_left(self.line, self.cursor))
      Byte('f') =>
        self.move_cursor(@unicode.char_size_right(self.line, self.cursor))
      Byte('l') => {
        self.output.cursor_to(col=0, row=0)
        self.output.clear_screen_down()
        self.refresh_line()
      }
      Byte('n') => self.history_next()
      Byte('p') => self.history_prev()
      Byte('y') => self.yank()
      Byte('z') => @spawn.kill(@spawn.getppid(), @signal.sigtstp)
      Byte('w') | Backspace => self.delete_word_left()
      Delete => self.delete_word_right()
      Left => self.word_left()
      Right => self.word_right()
      _ => ()
    }
  } else if key.meta {
    match key.name {
      Byte('b') => self.word_left()
      Byte('f') => self.word_right()
      Byte('d') | Delete => self.delete_word_right()
      Backspace => self.delete_word_left()
      Byte('y') => self.yank_pop()
      _ => ()
    }
  } else {
    if self.saw_return_at != 0 && !(key.name is Enter) {
      self.saw_return_at = 0
    }
    match key.name {
      Return => {
        self.saw_return_at = @env.now()
        self.line()
      }
      Enter => {
        if self.saw_return_at == 0 ||
          @env.now() - self.saw_return_at > self.crlf_delay {
          self.line()
        }
        self.saw_return_at = 0
      }
      Backspace => self.delete_left()
      Delete => self.delete_right()
      Left => self.move_cursor(-@unicode.char_size_left(self.line, self.cursor))
      Right =>
        self.move_cursor(@unicode.char_size_right(self.line, self.cursor))
      Home => self.move_cursor(-self.cursor)
      End => self.move_cursor(self.line.length() - self.cursor)
      Up => {
        should_reset_previous_cursor_cols = false
        self.move_up_or_history_prev()
      }
      Down => {
        should_reset_previous_cursor_cols = false
        self.move_down_or_history_next()
      }
      _ => {
        if key.name is Tab {
          if self.completer is Some(_) && self.is_completion_enabled {
            let last_keypress_was_tab = previous_key is Some(k) && k.name is Tab
            self.tab_complete(last_keypress_was_tab~)
          }
        }
        if keypress.sequence is Some(sequence) && sequence.length() > 0 {
          self.insert_string(key.sequence)
        }
      }
    }
  }
  if should_reset_previous_cursor_cols {
    self.previous_cursor_cols = -1
  }
}

///|
/// Start the background reader and keypress dispatcher tasks.
/// Call this before awaiting `read_line` or `read_key`.
pub async fn Interface::start(self : Interface) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => while true {
      self.emit_keypress()
    })
    group.spawn_bg(() => while true {
      let keypress = self.events.keypress.get()
      self.handle_keypress(keypress)
      self.events.key.put(keypress.key)
    })
  })
}

///|
/// Wait for the next completed line and return it as a UTF-8 string.
pub async fn Interface::read_line(self : Interface) -> String {
  match self.events.line.get() {
    line => @encoding/utf8.decode(line)
  }
}

///|
/// Wait for the next parsed key event.
pub async fn Interface::read_key(self : Interface) -> Key {
  self.events.key.get()
}

///|
/// Ask a one-off question using a temporary prompt.
/// Restores the previous prompt after the line is read.
pub async fn Interface::question(
  self : Interface,
  query : StringView,
) -> String {
  let query = @encoding/utf8.encode(query)
  self.old_prompt = self.prompt
  self.set_prompt(query)
  self.prompt()
  let line = @encoding/utf8.decode(self.events.line.get())
  self.set_prompt(self.old_prompt)
  line
}

///|
/// Render the prompt and current line buffer.
/// When `preserve_cursor` is false, the cursor resets to the start.
pub async fn Interface::prompt(
  self : Interface,
  preserve_cursor? : Bool = false,
) -> Unit {
  if !preserve_cursor {
    self.cursor = 0
  }
  self.refresh_line()
}
