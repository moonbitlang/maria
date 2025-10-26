///|
pub impl Show for MetaWriteToFileResult with output(
  self : MetaWriteToFileResult,
  logger : &Logger,
) -> Unit {
  let formatted = []
  formatted.push("Path: \{self.path}")
  formatted.push("Message: \{self.message}")
  formatted.push("Diff: \{self.diff}")
  let result = formatted.join("\n")
  logger.write_string(result)
}

///|
/// Parse and validate meta_write_to_file parameters
fn parse_meta_write_params(args : Json) -> MetaWriteParams? {
  guard args is { "path": String(path), "description": String(description), .. } else {
    return None
  }
  let search = match args {
    { "search": String(s), .. } => Some(s)
    _ => None
  }
  let replace = match args {
    { "replace": String(r), .. } => Some(r)
    _ => None
  }
  Some(MetaWriteParams::{ path, search, replace, description })
}
