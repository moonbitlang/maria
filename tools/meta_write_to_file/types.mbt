///|
pub struct MetaWriteToFileResult {
  path : String
  message : String
  diff : String
  learning_prompt : String?
} derive(ToJson, FromJson)

///|
/// Context needed for the syntax fixing sub-agent
priv struct FixingContext {
  path : String
  cwd : String
  mut result : String?
  /// Stores the fixed file content
  mut content : String
  description : String
  syntax_errors : String
  parent_agent : @agent.Agent
}

///|
/// Result of diff comparison between two strings
priv struct DiffResult {
  has_changes : Bool
  diff_text : String
}
