///|
/// Result of a successful match operation, containing position and length information
pub struct MatchResult {
  /// The starting position of the match in the original content
  position : Int32
  /// The length of the matched content
  length : Int32
  /// The starting line number of the match (0-indexed)
  start_line : Int32
  /// The ending line number of the match (0-indexed, inclusive)
  end_line : Int32
} derive(ToJson)

///|
pub extend MatchResult with ToJson::{to_json}
