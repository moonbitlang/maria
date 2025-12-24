///|
/// Represents a command loaded from a .md file
pub struct Command {
  /// Command name (derived from filename)
  name : String
  /// Command description from frontmatter
  description : String?
  /// Command content (markdown body after frontmatter)
  content : String
  /// File path where the command is defined
  location : String
} derive(Show, ToJson)

///|
/// Error type for command format/parsing errors
suberror CommandFormatError String derive(Show, ToJson)

///|
/// Parse a command from markdown content with YAML frontmatter
///
/// The command file should have the following structure:
/// ```markdown
/// ---
/// description: Command description
/// ---
///
/// Command content in natural language
/// ```
///
/// Parameters:
/// * `content` : The markdown file content
/// * `name` : The command name (usually derived from filename)
/// * `location` : The file path where the command is defined
///
/// Returns a `Command` object
/// Throws `CommandFormatError` if parsing fails
fn parse_command_from_content(
  content : String,
  name~ : String,
  location~ : String,
) -> Command raise {
  let doc = @yamd.parse(content)

  // Extract frontmatter metadata
  let meta = doc.meta
  let description = match meta.get("description") {
    Some(Json::String(s)) => Some(s)
    Some(s) =>
      raise CommandFormatError::CommandFormatError(
        "Field 'description' must be a string, got \{s.stringify()}",
      )
    None => None
  }
  Command::{ name, description, content: doc.text, location }
}

///|
test "parse_command_from_content" {
  let content =
    #|---
    #|description: "A test command"
    #|---
    #|
    #|This is a natural language command description.
    #|The AI should interpret this content directly.
    #|
  let cmd = try! parse_command_from_content(
    content.to_string(),
    name="greet",
    location="/path/to/greet.md",
  )
  @json.inspect(cmd, content={
    "name": "greet",
    "description": "A test command",
    "content": "\nThis is a natural language command description.\nThe AI should interpret this content directly.\n",
    "location": "/path/to/greet.md",
  })
}

///|
test "parse_command_from_content/no-frontmatter" {
  let content =
    #|# Simple command
    #|
    #|This is a command without frontmatter.
  let cmd = try! parse_command_from_content(
    content,
    name="simple",
    location="/path/to/simple.md",
  )
  @json.inspect(cmd, content={
    "name": "simple",
    "content": "",
    "location": "/path/to/simple.md",
  })
}
