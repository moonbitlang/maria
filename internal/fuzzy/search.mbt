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
/// Line-by-line fuzzy match (ignoring leading/trailing whitespace and empty lines)
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

  // Filter out empty lines for comparison
  let non_empty_needle_lines = trimmed_needle_lines.filter(fn(line) {
    line != ""
  })

  // If needle has no non-empty lines, no match
  if non_empty_needle_lines.length() == 0 {
    return None
  }

  /// Create a match result from start to end line indices
  /// Calculates the exact position and length of the match in the original content
  ///
  /// Parameters:
  ///
  /// * `start`: Starting line index in the haystack
  /// * `end`: Ending line index in the haystack (inclusive)
  ///
  /// Returns match result with position and length
  fn fuzzy_match_from_line(start : Int, end : Int) -> MatchResult {
    let matched_lines = []
    for i = start; i <= end; i = i + 1 {
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
    let end_line = end
    MatchResult::{
      position,
      length: matched_content.length(),
      start_line,
      end_line,
    }
  }

  // Compare lines ignoring whitespace and empty lines
  // Use variable-sized window to handle empty lines
  for i = 0; i < haystack_lines.length(); i = i + 1 {
    // Collect non-empty lines from haystack starting at position i
    let non_empty_haystack_window = []
    let mut end_idx = i
    let mut j = i

    // Expand window until we have enough non-empty lines or run out of haystack
    while non_empty_haystack_window.length() < non_empty_needle_lines.length() &&
          j < haystack_lines.length() {
      if trimmed_haystack_lines[j] != "" {
        non_empty_haystack_window.push(trimmed_haystack_lines[j])
      }
      end_idx = j
      j = j + 1
    }

    // Check if non-empty lines match
    if non_empty_haystack_window.length() == non_empty_needle_lines.length() {
      let mut line_matches = true
      for k = 0; k < non_empty_needle_lines.length(); k = k + 1 {
        if non_empty_haystack_window[k] != non_empty_needle_lines[k] {
          line_matches = false
          break
        }
      }
      if line_matches {
        return Some(fuzzy_match_from_line(i, end_idx))
      }
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
