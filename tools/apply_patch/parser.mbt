///|
const BEGIN_PATCH_MARKER = "*** Begin Patch"

///|
const END_PATCH_MARKER = "*** End Patch"

///|
const ADD_FILE_MARKER = "*** Add File: "

///|
const DELETE_FILE_MARKER = "*** Delete File: "

///|
const UPDATE_FILE_MARKER = "*** Update File: "

///|
const MOVE_TO_MARKER = "*** Move to: "

///|
const EOF_MARKER = "*** End of File"

///|
const CHANGE_CONTEXT_MARKER = "@@ "

///|
const EMPTY_CHANGE_CONTEXT_MARKER = "@@"

///|
const WHITESPACE = " \t\r\n"

///|
pub fn parse_patch(patch : String) -> ParsedPatch raise ParseError {
  let lines = patch
    .trim(chars=WHITESPACE)
    .to_string()
    .split("\n")
    .map(fn(sv) { sv.to_string() })
    .collect()
  guard lines.length() >= 2 else {
    raise InvalidPatch("Patch must have at least Begin and End markers")
  }
  let first = lines[0].trim(chars=" \t").to_string()
  guard first == BEGIN_PATCH_MARKER else {
    raise InvalidPatch(
      "The first line of the patch must be '\{BEGIN_PATCH_MARKER}'",
    )
  }
  let last = lines[lines.length() - 1].trim(chars=" \t").to_string()
  guard last == END_PATCH_MARKER else {
    raise InvalidPatch(
      "The last line of the patch must be '\{END_PATCH_MARKER}'",
    )
  }
  let hunks = []
  let mut i = 1
  let end = lines.length() - 1
  while i < end {
    let line = lines[i].trim(chars=" \t").to_string()
    if line.is_empty() {
      i += 1
      continue
    }
    let (hunk, lines_consumed) = parse_one_hunk(lines, i, end)
    hunks.push(hunk)
    i += lines_consumed
  }
  ParsedPatch::{ patch, hunks }
}

///|
fn parse_one_hunk(
  lines : Array[String],
  start : Int,
  end : Int,
) -> (Hunk, Int) raise ParseError {
  let first_line = lines[start].trim(chars=" \t").to_string()
  let line_number = start + 1
  if first_line.has_prefix(ADD_FILE_MARKER) {
    let path = try! first_line[ADD_FILE_MARKER.length():]
    let contents = StringBuilder::new()
    let mut parsed_lines = 1
    let mut i = start + 1
    while i < end {
      let line = lines[i]
      if line.has_prefix("+") {
        contents.write_string(try! line[1:].to_string())
        contents.write_char('\n')
        parsed_lines += 1
        i += 1
      } else {
        break
      }
    }
    return (
      AddFile(path=path.to_string(), contents=contents.to_string()),
      parsed_lines,
    )
  }
  if first_line.has_prefix(DELETE_FILE_MARKER) {
    let path = try! first_line[DELETE_FILE_MARKER.length():]
    return (DeleteFile(path=path.to_string()), 1)
  }
  if first_line.has_prefix(UPDATE_FILE_MARKER) {
    let path = try! first_line[UPDATE_FILE_MARKER.length():]
    let mut i = start + 1
    let mut parsed_lines = 1
    let move_path : String? = if i < end {
      let trimmed = lines[i].trim(chars=" \t").to_string()
      if trimmed.has_prefix(MOVE_TO_MARKER) {
        let mp = try! trimmed[MOVE_TO_MARKER.length():]
        i += 1
        parsed_lines += 1
        Some(mp.to_string())
      } else {
        None
      }
    } else {
      None
    }
    let chunks = []
    while i < end {
      let line = lines[i].trim(chars=" \t").to_string()
      if line.is_empty() {
        i += 1
        parsed_lines += 1
        continue
      }
      if line.has_prefix("***") && not(line.has_prefix(EOF_MARKER)) {
        break
      }
      let (chunk, chunk_lines) = parse_update_chunk(
        lines,
        i,
        end,
        chunks.is_empty(),
      )
      chunks.push(chunk)
      i += chunk_lines
      parsed_lines += chunk_lines
    }
    guard not(chunks.is_empty()) else {
      raise InvalidHunk(
        message="Update file hunk for path '\{path}' is empty",
        line_number~,
      )
    }
    return (
      UpdateFile(path=path.to_string(), move_path~, chunks~),
      parsed_lines,
    )
  }
  raise InvalidHunk(
    message="'\{first_line}' is not a valid hunk header. Valid: '\{ADD_FILE_MARKER}{{path}}', '\{DELETE_FILE_MARKER}{{path}}', '\{UPDATE_FILE_MARKER}{{path}}'",
    line_number~,
  )
}

///|
fn parse_update_chunk(
  lines : Array[String],
  start : Int,
  end : Int,
  allow_missing_context : Bool,
) -> (UpdateFileChunk, Int) raise ParseError {
  let first_line = lines[start].trim(chars=" \t").to_string()
  let line_number = start + 1
  let (change_context, start_index) : (String?, Int) = if first_line ==
    EMPTY_CHANGE_CONTEXT_MARKER {
    (None, 1)
  } else if first_line.has_prefix(CHANGE_CONTEXT_MARKER) {
    (Some(try! first_line[CHANGE_CONTEXT_MARKER.length():].to_string()), 1)
  } else if allow_missing_context {
    (None, 0)
  } else {
    raise InvalidHunk(
      message="Expected update hunk to start with a @@ context marker, got: '\{first_line}'",
      line_number~,
    )
  }
  let old_lines = []
  let new_lines = []
  let mut is_end_of_file = false
  let mut parsed_lines = start_index
  let mut i = start + start_index
  while i < end {
    let line = lines[i]
    let trimmed = line.trim(chars=" \t").to_string()
    if trimmed == EOF_MARKER {
      is_end_of_file = true
      parsed_lines += 1
      break
    }
    if trimmed.has_prefix("@@") || trimmed.has_prefix("***") {
      break
    }
    if line.is_empty() {
      old_lines.push("")
      new_lines.push("")
      parsed_lines += 1
      i += 1
      continue
    }
    match line[0] {
      ' ' => {
        let content = try! line[1:].to_string()
        old_lines.push(content)
        new_lines.push(content)
      }
      '+' => new_lines.push(try! line[1:].to_string())
      '-' => old_lines.push(try! line[1:].to_string())
      _ => {
        if parsed_lines == 0 {
          raise InvalidHunk(
            message="Unexpected line in update hunk: '\{line}'. Lines should start with ' ', '+', or '-'",
            line_number=line_number + parsed_lines,
          )
        }
        break
      }
    }
    parsed_lines += 1
    i += 1
  }
  (
    UpdateFileChunk::{ change_context, old_lines, new_lines, is_end_of_file },
    parsed_lines,
  )
}
