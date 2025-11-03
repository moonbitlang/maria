///|
pub impl Show for MetaWriteToFileResult with output(
  self : MetaWriteToFileResult,
  logger : &Logger,
) -> Unit {
  logger.write_string(self.message)
  logger.write_char('\n')
  if !self.diff.is_blank() {
    logger.write_string(self.diff)
    logger.write_char('\n')
  }
  if self.learning_prompt is Some(learning_prompt) {
    logger.write_char('\n')
    logger.write_string(learning_prompt)
    logger.write_char('\n')
  }
}

///|
test "MetaWriteToFileResult::Show" {
  let result = MetaWriteToFileResult::{
    path: "/var/folders/jb/64x3jtc51qbfk3y1m9f3yvyc0000gn/T/maria-test-smJHF4P/json_parser/json_parser/moon.pkg.json",
    message: "File written successfully to json_parser/json_parser/moon.pkg.json",
    diff: "\n\n**Diff:**\n```diff\n@@ -1,5 +1,5 @@\n {\n-  \"name\": \"json_parser\",\n+  \"name\": \"json_parser_updated\",\n   \"version\": \"0.1.0\",\n   \"dependencies\": {\n     \"moonbitlang/maria\": \"^0.1.0\"\n   }\n }\n```",
    learning_prompt: Some(
      (
        #|**⚠️ Syntax Error Learning Note:**
      ),
    ),
  }
  inspect(
    result,
    content=(
      #|File written successfully to json_parser/json_parser/moon.pkg.json
      #|
      #|
      #|**Diff:**
      #|```diff
      #|@@ -1,5 +1,5 @@
      #| {
      #|-  "name": "json_parser",
      #|+  "name": "json_parser_updated",
      #|   "version": "0.1.0",
      #|   "dependencies": {
      #|     "moonbitlang/maria": "^0.1.0"
      #|   }
      #| }
      #|```
      #|
      #|**⚠️ Syntax Error Learning Note:**
      #|
    ),
  )
}
