///|
/// Result of a successful match operation, containing position and length information
pub struct MatchResult {
  /// The starting position of the match in the original content
  position : Int
  /// The length of the matched content
  length : Int
  /// The starting line number of the match (0-indexed)
  start_line : Int
  /// The ending line number of the match (0-indexed, inclusive)
  end_line : Int
} derive(ToJson)
