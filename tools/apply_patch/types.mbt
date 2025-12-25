///|
pub(all) enum Hunk {
  AddFile(path~ : String, contents~ : String)
  DeleteFile(path~ : String)
  UpdateFile(
    path~ : String,
    move_path~ : String?,
    chunks~ : Array[UpdateFileChunk]
  )
} derive(Show, Eq)

///|
pub struct UpdateFileChunk {
  change_context : String?
  old_lines : Array[String]
  new_lines : Array[String]
  is_end_of_file : Bool
} derive(Show, Eq)

///|
pub struct ParsedPatch {
  patch : String
  hunks : Array[Hunk]
} derive(Show)

///|
pub(all) suberror ParseError {
  InvalidPatch(String)
  InvalidHunk(message~ : String, line_number~ : Int)
} derive(Show)

///|
pub struct ApplyResult {
  added : Array[String]
  modified : Array[String]
  deleted : Array[String]
} derive(Show)

///|
pub fn ApplyResult::new() -> ApplyResult {
  ApplyResult::{ added: [], modified: [], deleted: [] }
}

///|
pub fn ApplyResult::summary(self : ApplyResult) -> String {
  let lines : Array[String] = []
  lines.push("Success. Updated the following files:")
  for path in self.added {
    lines.push("A \{path}")
  }
  for path in self.modified {
    lines.push("M \{path}")
  }
  for path in self.deleted {
    lines.push("D \{path}")
  }
  lines.join("\n")
}
