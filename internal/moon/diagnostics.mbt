///|
pub async fn render_diagnostics(
  diagnostics : ArrayView[Diagnostic],
  limit~ : Int,
  context? : Int = 0,
  overlay? : Map[String, String] = {},
  cwd? : String,
) -> String noraise {
  let cache = {}
  for k, v in overlay {
    cache[k] = v.split("\n").collect()
  }
  let errors = @deque.new()
  let warnings = @deque.new()
  for d in diagnostics {
    match d.level {
      Error => errors.push_back(d)
      Warning => warnings.push_back(d)
    }
  }
  let limited_diagnostics = []
  while limited_diagnostics.length() < limit {
    if errors.pop_front() is Some(error) {
      limited_diagnostics.push(error)
      continue
    }
    if warnings.pop_front() is Some(warning) {
      limited_diagnostics.push(warning)
      continue
    }
    // No more diagnostics, stop processing
    break
  }
  let diagnostic_texts = []
  for diagnostic in limited_diagnostics {
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
    let message_lines = ["\{metadata}: \{diagnostic.message}"]
    if path == "" {
      diagnostic_texts.push(message_lines.join("\n"))
      continue
    }
    let lines = match cache.get(path) {
      Some(content) => content
      None => {
        let path = if cwd is Some(cwd) && !@path.is_absolute(path) {
          @path.join(cwd, path)
        } else {
          path
        }
        let content = @fs.read_file(path) catch {
          error => {
            message_lines.push("  (error reading file: \{error})")
            diagnostic_texts.push(message_lines.join("\n"))
            continue
          }
        }
        let lines = content.split("\n").collect()
        cache[path] = lines
        lines
      }
    }
    if diagnostic.loc.start.line != diagnostic.loc.end.line {
      let start_line = diagnostic.loc.start.line
      let end_line = diagnostic.loc.end.line
      let start_line_number = start_line.to_string()
      let end_line_number = end_line.to_string()
      let context_start_line = @cmp.maximum(1, start_line - context)
      let context_end_line = @cmp.minimum(
        lines.length() - 1,
        end_line + context,
      )
      let number_width = context_end_line.to_string().length()
      let number_padding = " ".repeat(number_width)
      let start_line_number = start_line_number.pad_start(number_width, ' ')
      let end_line_number = end_line_number.pad_start(number_width, ' ')
      for i in context_start_line..<start_line {
        let line_text = lines[i - 1]
        message_lines.push(" \{number_padding} │ \{line_text}")
      }
      let start_line_text = lines[diagnostic.loc.start.line - 1]
      message_lines.push(" \{start_line_number} │ \{start_line_text}")
      let text_padding = " ".repeat(diagnostic.loc.start.col - 1)
      let start_line_carets = "^".repeat(
        start_line_text.length() - diagnostic.loc.start.col + 1,
      )
      message_lines.push(
        " \{number_padding} │ \{text_padding}\{start_line_carets}",
      )
      if diagnostic.loc.start.line + 1 < diagnostic.loc.end.line {
        message_lines.push(" \{number_padding} ┆")
      }
      let end_line_text = lines[diagnostic.loc.end.line - 1]
      message_lines.push(" \{end_line_number} │ \{end_line_text}")
      let end_line_carets = "^".repeat(diagnostic.loc.end.col - 1)
      message_lines.push(" \{number_padding} │ \{end_line_carets}")
      for i in (end_line + 1)..=context_end_line {
        let line_text = lines[i - 1]
        message_lines.push(" \{number_padding} │ \{line_text}")
      }
    } else {
      let start_line = diagnostic.loc.start.line
      let context_start_line = @cmp.maximum(1, start_line - context)
      let context_end_line = @cmp.minimum(
        lines.length() - 1,
        start_line + context,
      )
      let number_width = context_end_line.to_string().length()
      let number_padding = " ".repeat(number_width)
      for i in context_start_line..<start_line {
        let line_text = lines[i - 1]
        message_lines.push(" \{number_padding} │ \{line_text}")
      }
      let start_line_number = start_line.to_string()
      let start_line_text = lines[start_line - 1]
      message_lines.push(" \{start_line_number} │ \{start_line_text}")
      let caret_text = "^".repeat(
        @cmp.maximum(diagnostic.loc.end.col - diagnostic.loc.start.col, 1),
      )
      let text_padding = " ".repeat(diagnostic.loc.start.col - 1)
      message_lines.push(" \{number_padding} │ \{text_padding}\{caret_text}")
      for i in (start_line + 1)..=context_end_line {
        let line_text = lines[i - 1]
        message_lines.push(" \{number_padding} │ \{line_text}")
      }
    }
    diagnostic_texts.push(message_lines.join("\n"))
  }
  let truncation_messages = []
  if errors.length() > 0 {
    truncation_messages.push("\{errors.length()} more error(s)")
  }
  if warnings.length() > 0 {
    truncation_messages.push("\{warnings.length()} more warning(s)")
  }
  if truncation_messages.length() > 0 {
    let truncation_message = StringBuilder::new()
    for i, message in truncation_messages {
      if i < truncation_messages.length() - 2 {
        truncation_message.write_string("\{message}, ")
      } else if i == truncation_messages.length() - 2 {
        truncation_message.write_string("\{message} and ")
      } else {
        truncation_message.write_string(message)
      }
    }
    diagnostic_texts.push(
      "There are \{truncation_message} not shown due to diagnostic limit.",
    )
  }
  return diagnostic_texts.join("\n\n")
}
