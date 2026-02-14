///|
pub(all) suberror ApplyError {
  ApplyError(String)
} derive(Show)

///|
pub async fn apply_hunks(
  hunks : ArrayView[Hunk],
  cwd : String,
) -> ApplyResult raise ApplyError {
  guard hunks.length() > 0 else { raise ApplyError("No files were modified.") }
  let result = ApplyResult::new()
  for hunk in hunks {
    apply_one_hunk(hunk, cwd, result)
  }
  result
}

///|
async fn apply_one_hunk(
  hunk : Hunk,
  cwd : String,
  result : ApplyResult,
) -> Unit raise ApplyError {
  match hunk {
    AddFile(path~, contents~) => {
      let full_path = resolve_path(cwd, path)
      let parent = @pathx.dirname(full_path)
      if not(parent.is_empty()) {
        @fsx.make_directory(parent, recursive=true, exists_ok=true) catch {
          err =>
            raise ApplyError("Failed to create directory \{parent}: \{err}")
        }
      }
      @fsx.write_to_file(full_path, contents) catch {
        err => raise ApplyError("Failed to create file \{full_path}: \{err}")
      }
      result.added.push(path)
    }
    DeleteFile(path~) => {
      let full_path = resolve_path(cwd, path)
      @fsx.remove(full_path) catch {
        err => raise ApplyError("Failed to delete file \{full_path}: \{err}")
      }
      result.deleted.push(path)
    }
    UpdateFile(path~, move_path~, chunks~) => {
      let full_path = resolve_path(cwd, path)
      let original = @fsx.read_file(full_path) catch {
        err => raise ApplyError("Failed to read file \{full_path}: \{err}")
      }
      let new_content = apply_chunks(original, chunks[:], full_path)
      let dest_path = match move_path {
        Some(mp) => resolve_path(cwd, mp)
        None => full_path
      }
      if move_path is Some(_) {
        let parent = @pathx.dirname(dest_path)
        if not(parent.is_empty()) {
          @fsx.make_directory(parent, recursive=true, exists_ok=true) catch {
            err =>
              raise ApplyError("Failed to create directory \{parent}: \{err}")
          }
        }
      }
      @fsx.write_to_file(dest_path, new_content) catch {
        err => raise ApplyError("Failed to write file \{dest_path}: \{err}")
      }
      if move_path is Some(_) {
        @fsx.remove(full_path) catch {
          err =>
            raise ApplyError(
              "Failed to remove original file \{full_path}: \{err}",
            )
        }
      }
      result.modified.push(move_path.unwrap_or(path))
    }
  }
}

///|
fn apply_chunks(
  original : String,
  chunks : ArrayView[UpdateFileChunk],
  path : String,
) -> String raise ApplyError {
  let lines : Array[String] = original
    .split("\n")
    .map(fn(sv) { sv.to_string() })
    .collect()
  if lines.length() > 0 && lines[lines.length() - 1].is_empty() {
    let _ = lines.pop()
  }
  let replacements : Array[(Int, Int, Array[String])] = []
  let mut line_index = 0
  for chunk in chunks {
    if chunk.change_context is Some(ctx) {
      match seek_line(lines[:], ctx, line_index) {
        Some(idx) => line_index = idx + 1
        None => raise ApplyError("Failed to find context '\{ctx}' in \{path}")
      }
    }
    if chunk.old_lines.is_empty() {
      let insertion_idx = if lines.length() > 0 &&
        lines[lines.length() - 1].is_empty() {
        lines.length() - 1
      } else {
        lines.length()
      }
      replacements.push((insertion_idx, 0, chunk.new_lines))
      continue
    }
    match
      seek_sequence(
        lines[:],
        chunk.old_lines[:],
        line_index,
        chunk.is_end_of_file,
      ) {
      Some(start_idx) => {
        replacements.push(
          (start_idx, chunk.old_lines.length(), chunk.new_lines),
        )
        line_index = start_idx + chunk.old_lines.length()
      }
      None => {
        let old_lines_str = chunk.old_lines.join("\n")
        raise ApplyError(
          "Failed to find expected lines in \{path}:\n\{old_lines_str}",
        )
      }
    }
  }
  replacements.sort_by(fn(a, b) { a.0.compare(b.0) })
  for i = replacements.length() - 1; i >= 0; i = i - 1 {
    let (start_idx, old_len, new_segment) = replacements[i]
    for _ in 0..<old_len {
      if start_idx < lines.length() {
        let _ = lines.remove(start_idx)
      }
    }
    for j, new_line in new_segment {
      lines.insert(start_idx + j, new_line)
    }
  }
  if lines.length() == 0 || not(lines[lines.length() - 1].is_empty()) {
    lines.push("")
  }
  lines.join("\n")
}

///|
fn seek_line(lines : ArrayView[String], target : String, start : Int) -> Int? {
  for i in start..<lines.length() {
    if lines[i].contains(target) {
      return Some(i)
    }
  }
  None
}

///|
fn seek_sequence(
  lines : ArrayView[String],
  pattern : ArrayView[String],
  start : Int,
  is_eof : Bool,
) -> Int? {
  if pattern.length() == 0 {
    return Some(start)
  }
  let search_end = if is_eof {
    (lines.length() - pattern.length()).max(start)
  } else {
    lines.length() - pattern.length() + 1
  }
  for i in start..<search_end {
    if matches_at(lines, pattern, i) {
      return Some(i)
    }
  }
  for i in start..<search_end {
    if matches_at_fuzzy(lines, pattern, i) {
      return Some(i)
    }
  }
  None
}

///|
fn matches_at(
  lines : ArrayView[String],
  pattern : ArrayView[String],
  pos : Int,
) -> Bool {
  if pos + pattern.length() > lines.length() {
    return false
  }
  for j in 0..<pattern.length() {
    if lines[pos + j] != pattern[j] {
      return false
    }
  }
  true
}

///|
fn matches_at_fuzzy(
  lines : ArrayView[String],
  pattern : ArrayView[String],
  pos : Int,
) -> Bool {
  if pos + pattern.length() > lines.length() {
    return false
  }
  for j in 0..<pattern.length() {
    if not(fuzzy_equals(lines[pos + j], pattern[j])) {
      return false
    }
  }
  true
}

///|
fn fuzzy_equals(a : String, b : String) -> Bool {
  if a == b {
    return true
  }
  normalize_punctuation(a) == normalize_punctuation(b)
}

///|
fn normalize_punctuation(s : String) -> String {
  let result = StringBuilder::new()
  for c in s {
    let normalized = match c {
      '\u{2013}' | '\u{2014}' | '\u{2011}' => '-' // en-dash, em-dash, non-breaking hyphen
      '\u{2018}' | '\u{2019}' => '\'' // smart single quotes
      '\u{201C}' | '\u{201D}' => '"' // smart double quotes
      '\u{00A0}' => ' ' // non-breaking space
      _ => c
    }
    result.write_char(normalized)
  }
  result.to_string()
}

///|
fn resolve_path(cwd : String, path : String) -> String {
  if @pathx.is_absolute(path) {
    path
  } else {
    @pathx.join(cwd, path)
  }
}
