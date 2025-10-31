///|
/// Result of a successful match operation, containing position and length information
pub struct MatchResult {
  /// The starting position of the match in the original content
  position : Int
  /// The length of the matched content
  length : Int
} derive(ToJson)
