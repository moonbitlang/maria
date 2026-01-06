///|
pub struct Skill {
  name : String
  description : String
  license : String?
  compatibility : String?
  /// - A space-delimited list of tools that are pre-approved to run
  /// - Experimental. Support for this field may vary between agent implementations
  allowed_tools : Array[String]
  metadata : Json?
  location : String
} derive(Show, ToJson)

///|
fn validate_name(
  name : String,
  directory~ : String,
) -> Unit raise SkillFormatError {
  if name.is_empty() {
    raise SkillFormatError("Field 'name' must be a non-empty string")
  }
  if name.length() > 64 {
    raise SkillFormatError("Skill name exceeds 64 character limit")
  }
  if name.has_prefix("-") || name.has_suffix("-") {
    raise SkillFormatError("Skill name cannot start or end with a hyphen")
  }
  if name.contains("--") {
    raise SkillFormatError("Skill name cannot contain consecutive hyphens")
  }
  if !directory.is_empty() && directory != name {
    raise SkillFormatError("Directory name must match skill name")
  }
}

///|
fn validate_description(desc : String) -> Unit raise SkillFormatError {
  if desc.is_empty() {
    raise SkillFormatError("Field 'description' must be a non-empty string")
  }
  if desc.length() > 1024 {
    raise SkillFormatError("Description exceeds 1024 character limit")
  }
}

///|
priv suberror SkillFormatError String derive(Show, ToJson)

///|
/// Parses a skill definition from YAML frontmatter content and creates a
/// `Skill` object.
///
/// Parameters:
///
/// * `content` : The YAML frontmatter content containing skill metadata and
///   description.
/// * `directory` : The directory name where the skill file is located, used for
///   validation against the skill name.
/// * `location` : The file path where the skill is located.
///
/// Returns a `Skill` object populated with the parsed metadata and content.
///
/// Throws an error of type `SkillFormatError` if:
///
/// * Required fields (`name` or `description`) are missing from the frontmatter
/// * Field types are incorrect (e.g., `name` or `description` is not a string)
/// * The skill name fails validation (empty, too long, invalid format, or
///   doesn't match directory name)
/// * The description fails validation (empty or too long)
/// * The `allowed-tools` field is neither a space-delimited string nor a valid
///   JSON array of strings
fn parse_skill_from_content(
  content : String,
  directory~ : String,
  location~ : String,
) -> Skill raise {
  let doc = @yamd.parse(content)
  // Extract frontmatter
  let meta = doc.meta
  let name = match meta.get("name") {
    Some(String(s)) => s
    Some(s) =>
      raise SkillFormatError(
        "Field 'name' must be a string, got \{s.stringify()}",
      )
    None => raise SkillFormatError("Missing field 'name'")
  }
  validate_name(name, directory~)
  let description = match meta.get("description") {
    Some(String(s)) => s
    Some(s) =>
      raise SkillFormatError(
        "Field 'description' must be a string, got \{s.stringify()}",
      )
    None => raise SkillFormatError("Missing field 'description'")
  }
  validate_description(description)
  let license = match meta.get("license") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let compatibility = match meta.get("compatibility") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let allowed_tools : Array[String] = match meta.get("allowed-tools") {
    Some(String(s)) => s.split(" ").map(tool => tool.to_string()).collect()
    Some(s) =>
      @json.from_json(s) catch {
        _ =>
          raise SkillFormatError(
            "Field 'allowed-tools' must be a space-delimited string or array of strings, got \{s.stringify()}",
          )
      }
    _ => []
  }
  let metadata : Json? = meta.get("metadata")
  Skill::{
    name,
    description,
    license,
    compatibility,
    allowed_tools,
    metadata,
    location,
  }
}
