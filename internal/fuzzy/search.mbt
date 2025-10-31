///|
/// Find a match in the haystack string using various matching strategies
///
/// Implements three matching strategies in order:
/// 1. Direct match: Exact string comparison
/// 2. Line-by-line: Compare each line ignoring leading/trailing whitespace
/// 3. First/last line match: For blocks ≥3 lines, match first and last lines
///
/// @param haystack The string to search in
/// @param needle The string to search for
/// @param fuzzy_match Whether to use fuzzy matching strategies (default: true)
/// @return Match result containing position and length, or None if no match found
pub fn find_match(
  haystack : String,
  needle : String,
  fuzzy_match? : Bool = true,
) -> MatchResult? {
  // Strategy 1: Direct match
  match haystack.find(needle) {
    None =>
      // Continue to fuzzy matching if enabled
      if !fuzzy_match {
        return None
      }
    Some(exact_match) =>
      return Some(MatchResult::{
        position: exact_match,
        length: needle.length(),
      })
  }

  // Prepare for line-based fuzzy matches
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
  /// @param start Starting line index in the haystack
  /// @return Match result with position and length
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
    MatchResult::{ position, length: matched_content.length() }
  }

  // Strategy 2: Line-by-line comparison ignoring whitespace
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
