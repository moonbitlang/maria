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
