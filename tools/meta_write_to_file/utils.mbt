///|
/// Generate a diff between old and new content (naive implementation)
/// TODO: replace with more reasonable diff generation (e.g., using git diff)
async fn generate_diff(
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
  diff_text.write_string(
    @git.generate_git_diff(original=old_content, modified=new_content),
  )
  diff_text.write_string("\n```")
  DiffResult::{ has_changes: true, diff_text: diff_text.to_string() }
}
