///|
pub struct Diagnostics(Array[Diagnostic]) derive(ToJson, Show)

///|
pub fn Diagnostics::new() -> Self {
  []
}

///|
pub fn Diagnostics::clear(self : Diagnostics) -> Unit {
  self.0.clear()
}

///|
pub fn Diagnostics::append(
  self : Diagnostics,
  diagnostic : Diagnostics,
) -> Unit {
  self.0.append(diagnostic.0)
}

///|
pub fn Diagnostics::push(self : Diagnostics, diagnostic : Diagnostic) -> Unit {
  self.0.push(diagnostic)
}

///|
pub fn Diagnostics::filter_map(
  self : Diagnostics,
  f : (Diagnostic) -> Diagnostic?,
) -> Diagnostics {
  self.0.filter_map(f)
}

///|
pub fn Diagnostics::length(self : Diagnostics) -> Int {
  self.0.length()
}

///|
pub fn Diagnostics::is_empty(self : Diagnostics) -> Bool {
  self.0.is_empty()
}

///|
pub fn Diagnostics::iterator(self : Diagnostics) -> Iterator[Diagnostic] {
  self.0.iterator()
}

///|
fn partition_diagnostics(
  diagnostics : Array[Diagnostic],
) -> (@deque.Deque[Diagnostic], @deque.Deque[Diagnostic]) {
  let errors = @deque.new()
  let warnings = @deque.new()
  for diagnostic in diagnostics {
    match diagnostic.level {
      Error => errors.push_back(diagnostic)
      Warning => warnings.push_back(diagnostic)
    }
  }
  (errors, warnings)
}

///|
fn take_limited_diagnostics(
  errors : @deque.Deque[Diagnostic],
  warnings : @deque.Deque[Diagnostic],
  limit : Int,
) -> Array[Diagnostic] {
  let limited = []
  while limited.length() < limit {
    if errors.pop_front() is Some(error) {
      limited.push(error)
      continue
    }
    if warnings.pop_front() is Some(warning) {
      limited.push(warning)
      continue
    }
    break
  }
  limited
}

///|
fn format_metadata_and_path(diagnostic : Diagnostic) -> (String, String) {
  let metadata = StringBuilder::new()
  let error_code_text = diagnostic.error_code.to_string().pad_start(4, '0')
  match diagnostic.level {
    Error => metadata.write_string("error[\{error_code_text}]")
    Warning => metadata.write_string("warning[\{error_code_text}]")
  }
  let path = diagnostic.loc.path.trim_space().to_string()
  if path != "" {
    if diagnostic.loc.start.line == diagnostic.loc.end.line {
      if diagnostic.loc.start.col == diagnostic.loc.end.col {
        metadata.write_string(
          ": \{diagnostic.loc.path}:\{diagnostic.loc.start.line}:\{diagnostic.loc.start.col}",
        )
      } else {
        metadata.write_string(
          ": \{diagnostic.loc.path}:\{diagnostic.loc.start.line}:\{diagnostic.loc.start.col}-\{diagnostic.loc.end.col}",
        )
      }
    } else {
      metadata.write_string(
        ": \{diagnostic.loc.path}:\{diagnostic.loc.start.line}:\{diagnostic.loc.start.col}-\{diagnostic.loc.end.line}:\{diagnostic.loc.end.col}",
      )
    }
  }
  (metadata.to_string(), path)
}

///|
fn render_single_line_range(
  diagnostic : Diagnostic,
  lines : Array[StringView],
  context : Int,
) -> Array[String] {
  let rendered = []
  let start_line = diagnostic.loc.start.line
  let context_start_line = @cmp.maximum(1, start_line - context)
  let context_end_line = @cmp.minimum(lines.length() - 1, start_line + context)
  let number_width = context_end_line.to_string().length()
  let number_padding = " ".repeat(number_width)
  for i in context_start_line..<start_line {
    let line_text = lines[i - 1]
    rendered.push(" \{number_padding} │ \{line_text}")
  }
  let start_line_number = start_line.to_string()
  let start_line_text = lines[start_line - 1]
  rendered.push(" \{start_line_number} │ \{start_line_text}")
  let caret_text = "^".repeat(
    @cmp.maximum(diagnostic.loc.end.col - diagnostic.loc.start.col, 1),
  )
  let text_padding = " ".repeat(diagnostic.loc.start.col - 1)
  rendered.push(" \{number_padding} │ \{text_padding}\{caret_text}")
  for i in (start_line + 1)..=context_end_line {
    let line_text = lines[i - 1]
    rendered.push(" \{number_padding} │ \{line_text}")
  }
  rendered
}

///|
fn render_multi_line_range(
  diagnostic : Diagnostic,
  lines : Array[StringView],
  context : Int,
) -> Array[String] {
  let rendered = []
  let start_line = diagnostic.loc.start.line
  let end_line = diagnostic.loc.end.line
  let start_line_number = start_line.to_string()
  let end_line_number = end_line.to_string()
  let context_start_line = @cmp.maximum(1, start_line - context)
  let context_end_line = @cmp.minimum(lines.length() - 1, end_line + context)
  let number_width = context_end_line.to_string().length()
  let number_padding = " ".repeat(number_width)
  let start_line_number = start_line_number.pad_start(number_width, ' ')
  let end_line_number = end_line_number.pad_start(number_width, ' ')
  for i in context_start_line..<start_line {
    let line_text = lines[i - 1]
    rendered.push(" \{number_padding} │ \{line_text}")
  }
  let start_line_text = lines[start_line - 1]
  rendered.push(" \{start_line_number} │ \{start_line_text}")
  let text_padding = " ".repeat(diagnostic.loc.start.col - 1)
  let start_line_carets = "^".repeat(
    start_line_text.length() - diagnostic.loc.start.col + 1,
  )
  rendered.push(" \{number_padding} │ \{text_padding}\{start_line_carets}")
  if diagnostic.loc.start.line + 1 < diagnostic.loc.end.line {
    rendered.push(" \{number_padding} ┆")
  }
  let end_line_text = lines[end_line - 1]
  rendered.push(" \{end_line_number} │ \{end_line_text}")
  let end_line_carets = "^".repeat(diagnostic.loc.end.col - 1)
  rendered.push(" \{number_padding} │ \{end_line_carets}")
  for i in (end_line + 1)..=context_end_line {
    let line_text = lines[i - 1]
    rendered.push(" \{number_padding} │ \{line_text}")
  }
  rendered
}

///|
fn render_range_lines(
  diagnostic : Diagnostic,
  lines : Array[StringView],
  context : Int,
) -> Array[String] {
  if diagnostic.loc.start.line != diagnostic.loc.end.line {
    render_multi_line_range(diagnostic, lines, context)
  } else {
    render_single_line_range(diagnostic, lines, context)
  }
}

///|
async fn render_diagnostic_entry(
  diagnostic : Diagnostic,
  cache : Map[String, Array[StringView]],
  context : Int,
  cwd? : String,
) -> String noraise {
  let (metadata, trimmed_path) = format_metadata_and_path(diagnostic)
  let message_lines = []
  message_lines.push("\{metadata}: \{diagnostic.message}")
  if trimmed_path == "" {
    return message_lines.join("\n")
  }
  let lines = match cache.get(trimmed_path) {
    Some(lines) => lines
    None => {
      let resolved_path = if cwd is Some(cwd) &&
        !@path.is_absolute(trimmed_path) {
        @path.join(cwd, trimmed_path)
      } else {
        trimmed_path
      }
      let content = @fs.read_file(resolved_path) catch {
        error => {
          message_lines.push("  (error reading file: \{error})")
          return message_lines.join("\n")
        }
      }
      let lines = content.split("\n").collect()
      cache[resolved_path] = lines
      if resolved_path != trimmed_path {
        cache[trimmed_path] = lines
      }
      lines
    }
  }
  let rendered_lines = render_range_lines(diagnostic, lines, context)
  message_lines.append(rendered_lines)
  message_lines.join("\n")
}

///|
fn format_truncation_summary(truncation_messages : Array[String]) -> String? {
  guard truncation_messages.length() != 0 else { return None }
  let summary = StringBuilder::new()
  for i, message in truncation_messages {
    if i < truncation_messages.length() - 2 {
      summary.write_string("\{message}, ")
    } else if i == truncation_messages.length() - 2 {
      summary.write_string("\{message} and ")
    } else {
      summary.write_string(message)
    }
  }
  Some("There are \{summary} not shown due to diagnostic limit.")
}

///|
pub fn from_jsonl(jsonl : StringView) -> Diagnostics {
  let diagnostics = []
  for line in jsonl.split("\n") {
    let line = line.trim_space()
    try {
      let json = @json.parse(line)
      // TODO: fail on json decoding??
      let diag : Diagnostic = @json.from_json(json) catch {
        error =>
          fail(
            "Failed to parse diagnostic from JSON: \{error} (line: '\{line}')",
          )
      }
      diagnostics.push(diag)
    } catch {
      _ => () // continue
    }
  }
  diagnostics
}

///|
/// Renders diagnostics into a human-readable report, prioritising errors and
/// falling back to warnings once the error limit is reached.
///
/// Parameters:
/// * `context` – how many lines of surrounding source should be displayed on
///   either side of the highlighted region.
/// * `overlay` – optional in-memory file contents keyed by path for surfacing
///   diagnostics against unsaved edits.
pub async fn Diagnostics::render(
  diagnostics : Diagnostics,
  limit~ : Int,
  context? : Int = 0,
  overlay? : Map[String, String] = {},
  cwd? : String,
) -> String noraise {
  let diagnostics = diagnostics.0
  let cache = {}
  for k, v in overlay {
    cache[k] = v.split("\n").to_array()
  }
  let (errors, warnings) = partition_diagnostics(diagnostics)
  let limited_diagnostics = take_limited_diagnostics(errors, warnings, limit)
  let diagnostic_texts = []
  for diagnostic in limited_diagnostics {
    diagnostic_texts.push(
      render_diagnostic_entry(diagnostic, cache, context, cwd?),
    )
  }
  let truncation_messages = []
  if errors.length() > 0 {
    truncation_messages.push("\{errors.length()} more error(s)")
  }
  if warnings.length() > 0 {
    truncation_messages.push("\{warnings.length()} more warning(s)")
  }
  if format_truncation_summary(truncation_messages) is Some(summary) {
    diagnostic_texts.push(summary)
  }
  return diagnostic_texts.join("\n\n")
}

///|
test "format_truncation_summary-empty" {
  assert_eq(format_truncation_summary([]), None)
}

///|
test "format_truncation_summary-single" {
  let expected = "There are 1 more error(s) not shown due to diagnostic limit."
  assert_eq(format_truncation_summary(["1 more error(s)"]), Some(expected))
}

///|
test "format_truncation_summary-multiple" {
  let messages = ["2 more error(s)", "3 more warning(s)"]
  let expected = "There are 2 more error(s) and 3 more warning(s) not shown due to diagnostic limit."
  assert_eq(format_truncation_summary(messages), Some(expected))
}

///|
test "format_truncation_summary-three" {
  let messages = ["2 more error(s)", "3 more warning(s)", "1 more note"]
  let expected = "There are 2 more error(s), 3 more warning(s) and 1 more note not shown due to diagnostic limit."
  assert_eq(format_truncation_summary(messages), Some(expected))
}
