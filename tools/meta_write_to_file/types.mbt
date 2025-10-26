///|
/// Parameters for the meta_write_to_file tool
priv struct MetaWriteParams {
  path : String
  search : String?
  replace : String?
  description : String
}

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
  file_path : String
  cwd : String
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
