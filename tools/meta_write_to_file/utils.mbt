///|
/// Generate a diff between old and new content (naive implementation)
/// TODO: replace with more reasonable diff generation (e.g., using git diff)
fn generate_diff(
  old_content : String,
  new_content : String,
  title : String,
) -> DiffResult {
  if old_content == new_content {
    return DiffResult::{ has_changes: false, diff_text: "" }
  }

  // Simple diff implementation - in a real implementation you'd use git diff
  let diff_text = StringBuilder::new()
  diff_text.write_string("\n\n**\{title}:**\n```diff\n")
  let old_lines = old_content.split("\n").to_array()
  let new_lines = new_content.split("\n").to_array()

  // Simplified line-by-line diff
  let max_lines = @cmp.maximum(old_lines.length(), new_lines.length())
  for i = 0; i < max_lines; i = i + 1 {
    let old_line = if i < old_lines.length() { old_lines[i] } else { "" }
    let new_line = if i < new_lines.length() { new_lines[i] } else { "" }
    if old_line != new_line {
      if old_line != "" {
        diff_text.write_string("-\{old_line}\n")
      }
      if new_line != "" {
        diff_text.write_string("+\{new_line}\n")
      }
    }
  }
  diff_text.write_string("```")
  DiffResult::{ has_changes: true, diff_text: diff_text.to_string() }
}

///|
test "generate_diff with changes" {
  // let old = "line1\nline2\nline3"
  let old =
    #|line1
    #|line2
    #|line3
  let new =
    #|line1
    #|lineX
    #|line3
    #|line4
  let diff = generate_diff(old, new, "Test File")
  inspect(diff.has_changes, content="true")
  inspect(
    diff.diff_text,
    content=(
      #|
      #|
      #|**Test File:**
      #|```diff
      #|-line2
      #|+lineX
      #|+line4
      #|```
    ),
  )
}
