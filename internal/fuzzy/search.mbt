///|
/// Exact string match
///
/// Parameters:
///
/// * `haystack`: The string to search in
/// * `needle`: The string to search for
///
/// Returns match result if exact match found, None otherwise
fn try_exact_match(haystack : String, needle : String) -> MatchResult? {
  match haystack.find(needle) {
    Some(position) => {
      // Calculate line numbers for the match
      let before_match = try! haystack[0:position].to_string()
      let start_line = before_match.split("\n").to_array().length() - 1
      let needle_lines = needle.split("\n").to_array().length()
      let end_line = start_line + needle_lines - 1
      Some(MatchResult::{
        position,
        length: needle.length(),
        start_line,
        end_line,
      })
    }
    None => None
  }
}

///|
/// Line-by-line fuzzy match (ignoring leading/trailing whitespace)
///
/// Parameters:
///
/// * `haystack`: The string to search in
/// * `needle`: The string to search for
///
/// Returns match result if fuzzy match found, `None` otherwise
fn try_line_by_line_match(haystack : String, needle : String) -> MatchResult? {
  let haystack_lines = haystack.split("\n").to_array()
  let needle_lines = needle.split("\n").to_array()
  let trimmed_haystack_lines = haystack_lines.map(fn(line) {
    line.trim(char_set=" \t\r\n").to_string()
  })
  let trimmed_needle_lines = needle_lines.map(fn(line) {
    line.trim(char_set=" \t\r\n").to_string()
  })

  /// Create a match result starting from a specific line index
  /// Calculates the exact position and length of the match in the original content
  ///
  /// Parameters:
  ///
  /// * `start`: Starting line index in the haystack
  ///
  /// Returns match result with position and length
  fn fuzzy_match_from_line(start : Int) -> MatchResult {
    let matched_lines = []
    for i = start; i < start + needle_lines.length(); i = i + 1 {
      matched_lines.push(haystack_lines[i])
    }
    let matched_content = matched_lines.join("\n")
    let position = if start > 0 {
      let before_lines = []
      for i = 0; i < start; i = i + 1 {
        before_lines.push(haystack_lines[i])
      }
      before_lines.join("\n").length() + 1 // +1 for newline
    } else {
      0
    }
    let start_line = start
    let end_line = start + needle_lines.length() - 1
    MatchResult::{
      position,
      length: matched_content.length(),
      start_line,
      end_line,
    }
  }

  // Compare lines ignoring whitespace
  for i = 0; i <= haystack_lines.length() - needle_lines.length(); i = i + 1 {
    let mut line_matches = true
    for j = 0; j < needle_lines.length(); j = j + 1 {
      if trimmed_haystack_lines[i + j] != trimmed_needle_lines[j] {
        line_matches = false
        break
      }
    }
    if line_matches {
      return Some(fuzzy_match_from_line(i))
    }
  }
  None
}

///|
/// Find a match in the haystack string using various matching strategies
///
/// Implements multiple matching strategies in order:
/// 1. Direct match: Exact string comparison
/// 2. Line-by-line: Compare each line ignoring leading/trailing whitespace
///
/// Parameters:
///
/// * `haystack`: The string to search in
/// * `needle`: The string to search for
///
/// Returns match result containing position and length, or None if no match found
pub fn find_match(haystack : String, needle : String) -> MatchResult? {
  // Strategy 1: Exact match
  if try_exact_match(haystack, needle) is Some(result) {
    return Some(result)
  }

  // Strategy 2: Line-by-line comparison ignoring whitespace
  try_line_by_line_match(haystack, needle)
}
