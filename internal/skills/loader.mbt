///|
/// Skill loader that manages and loads skills from both global and local
/// directories.
///
/// The loader searches for skills in `.moonagent/skills` directories:
///
/// - Global skills: `~/.moonagent/skills`
/// - Local skills: starting from the current working directory and walking up
///   through parent directories.
///
/// The upward walk stops when it reaches:
///
/// - When inside a Git repo: the Git repo root (directory containing `.git`)
/// - When not inside a Git repo: the current working directory and the user's home directory
///
/// Each skill is expected to have a `SKILL.md` or `skill.md` file containing its
/// definition.
struct Loader {
  /// Logger instance for operation logging.
  logger : @pino.Logger
  /// Home directory path for global skills.
  home : String
  /// Current working directory path for local skills.
  cwd : String
  /// Map of loaded skills indexed by skill name.
  skills : Map[String, Skill]
}

///|
/// Creates a new skill loader with the specified configuration.
///
/// Parameters:
///
/// * `home` : The home directory path for global skills. If not provided, uses
///   the system's home directory.
/// * `cwd` : The current working directory path for local skills.
/// * `logger` : The logger instance for logging operations. Defaults to a
///   console logger with the name "skills".
///
/// Returns a new `Loader` instance with an empty skills map.
///
/// Throws an error if the system's home directory cannot be determined when
/// `home` is not provided.
///
/// Example:
///
/// ```moonbit
/// let loader = @skills.Loader::new(cwd="/path/to/project")
/// ```
pub fn Loader::new(
  home? : String,
  cwd~ : String,
  logger? : @pino.Logger = @pino.logger("skills", @pino.Transport::console()),
) -> Loader raise {
  let home = match home {
    Some(home) => home
    None => @os.home()
  }
  Loader::{ home, cwd, logger, skills: {} }
}

///|
/// Loads skills from a specified directory by scanning for skill definition
/// files and parsing them into the loader's skill map.
///
/// Parameters:
///
/// * `self` : The loader instance to populate with discovered skills.
/// * `directory` : The directory path to scan for skill subdirectories.
///
/// Throws:
///
/// This method can throw various errors during file system operations:
///
/// * File system errors when accessing directories or reading files
/// * Parsing errors when processing skill definition files (these are caught
///   and logged as warnings)
async fn Loader::load_skills_from_directory(
  self : Loader,
  directory : String,
) -> Unit {
  if !@fsx.exists(directory) {
    // Directory does not exist, nothing to load. It is rather normal for user
    // to not have skills directory setup, so we just log a debug message.
    self.logger.debug(
      "Skills directory '\{directory}' does not exist, skipping.",
    )
    return
  }
  self.logger.info("Loading skills from directory '\{directory}'...")
  let entries = @fsx.list_directory(directory).filter(e => e.kind
    is @fsx.FileKind::Directory)
  for entry in entries {
    let skill_dir = @pathx.join(directory, entry.name)
    let upper = @pathx.join(skill_dir, "SKILL.md")
    let lower = @pathx.join(skill_dir, "skill.md")
    let path = if @fsx.exists(upper) {
      upper
    } else if @fsx.exists(lower) {
      lower
    } else {
      // According to spec, SKILL.md is required. Log an error and skip.
      self.logger.error(
        "Missing SKILL.md in skill directory '\{skill_dir}', skipping.",
      )
      continue
    }
    let content = @fsx.read_file(path)
    let location = @fsx.resolve(path)
    let skill = parse_skill_from_content(
      content,
      directory=entry.name,
      location~,
    ) catch {
      error => {
        self.logger.warn(
          "Failed to parse skill in '\{skill_dir}': \{error}, skipping.",
        )
        continue
      }
    }
    self.logger.info("Loaded skill '\{skill.name}' from '\{skill_dir}'.")
    self.skills[skill.name] = skill
  }
}

///|
/// Loads skills from both global and local directories into the loader.
///
/// Parameters:
///
/// * `self` : The loader instance to populate with skills.
pub async fn Loader::load(self : Loader) -> Unit {
  self.skills.clear()
  let global_path = self.home
    |> @pathx.join(".moonagent")
    |> @pathx.join("skills")
  self.load_skills_from_directory(global_path)

  // Determine local skill search roots.
  //
  // New rules:
  // 1) If `.git` exists in cwd or any ancestor, treat that directory as the repo
  //    root and load skills from cwd up to that repo root (inclusive).
  // 2) If no `.git` exists in any ancestor, load skills from cwd and home only.
  //
  // Precedence rule: load from the furthest directory first so closer directories
  // override earlier ones.
  let cwd_norm = @pathx.normalize(self.cwd[:])
  let home_norm = @pathx.normalize(self.home[:])
  let repo_root = @git.find_repo_root(cwd_norm[:])
  let dirs : Array[String] = []
  match repo_root {
    Some(root) => {
      // Walk up from cwd to git repo root (inclusive).
      let root_norm = @pathx.normalize(root[:])
      let mut cur = cwd_norm
      while true {
        dirs.push(cur)
        if cur == root_norm {
          break
        }
        let parent = @pathx.dirname(cur).to_string()
        // Safety: if we can't reach root for some reason, stop at filesystem root.
        if parent == cur {
          break
        }
        cur = parent
      }
    }
    None =>
      // Not in a git repo: load from cwd and home.
      //
      // Note: global skills (`home/.moonagent/skills`) are already loaded above,
      // so we only need to add `cwd` here (and only if it differs from home) to
      // avoid loading the same directory twice.
      if cwd_norm != home_norm {
        dirs.push(cwd_norm)
      }
  }
  for dir in dirs.rev() {
    let local_path = dir |> @pathx.join(".moonagent") |> @pathx.join("skills")
    self.load_skills_from_directory(local_path)
  }
}

///|
/// Formats all loaded skills into an XML string representation for use in AI
/// prompts.
///
/// Parameters:
///
/// * `self` : The loader instance containing the skills to format.
///
/// Returns a string containing XML-formatted skill information, with each skill
/// wrapped in `<skill>` tags containing `<name>`, `<description>`, and
/// `<location>` elements, all enclosed within `<available_skills>` root tags.
fn Loader::format_prompt(self : Loader) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    (
      #|====
      #|
      #|SKILLS
      #|
      #|You are equipped with skill capabilities that you can use to solve many
      #|tasks. A skill is a folder containing a SKILL.md file. This file includes:
      #|
      #|- name: The name of the skill
      #|- description: A brief description of what the skill does
      #|- location: The location of the skill on disk
      #|- instructions (as the main body): Instructions on how to use the skill.
      #|
      #|Optionally, a skill folder may also contain:
      #|
      #|- scripts: Python/Shell/... scripts for common operations
      #|- references: Reference materials such as documentation, cheat sheets,
      #|  etc.
      #|- templates: Code templates/snippets for common patterns
      #|
      #|Here is an example layout of a skill folder:
      #|
      #|```plaintext
      #|skills/
      #|  my-skill/
      #|    SKILL.md
      #|    scripts/
      #|      helper.py
      #|    references/
      #|      doc.md
      #|    templates/
      #|      snippet.mbt
      #|```
      #|
      #|To use skills efficiently, you should follow a progressive approach to
      #|discover, load and apply skills to tasks. Usually, this means:
      #|
      #|1. First, You should identify relevant skills for the task from the
      #|available skills list below.
      #|
      #|2. Next, You should load the identified skills into your working context,
      #|by reading their SKILL.md files. Note that you probably want to defer
      #|the loading of resources such as scripts, references, templates until they
      #|are actually needed.
      #|
      #|3. Finally, you should utilize the knowledge/rules/instructions provided
      #|by the loaded SKILL.md files to assist in completing the task. Optionally
      #|you may want to leverage the scripts/templates/references provided by
      #|the skill folders to accomplish the task.
      #|
    ),
  )
  sb.write_string("<available_skills>\n")
  for _, skill in self.skills {
    sb.write_string("  <skill>\n")
    sb.write_string("    <name>")
    sb.write_string(skill.name)
    sb.write_string("</name>\n")
    sb.write_string("    <description>")
    sb.write_string(skill.description)
    sb.write_string("</description>\n")
    sb.write_string("    <location>")
    sb.write_string(skill.location)
    sb.write_string("</location>\n")
    sb.write_string("  </skill>\n")
  }
  sb.write_string("</available_skills>")
  sb.to_string()
}

///|
/// Applies the loaded skills to an array of AI messages by appending skill
/// information to the system message.
///
/// Parameters:
///
/// * `self` : The loader instance containing the skills to apply.
/// * `messages` : The array of AI messages to modify. The first system message
///   in this array will have skill information appended to its content.
fn Loader::apply(self : Loader, messages : Array[@ai.Message]) -> Unit {
  if self.skills.is_empty() {
    return
  }
  let skill_prompt = self.format_prompt()
  // Find the system message
  for i, msg in messages {
    if msg is System(sys_msg) {
      messages[i] = @ai.system_message(content=sys_msg + "\n\n" + skill_prompt)
      return
    }
  } else {
    // No system message found, prepend a system prompt with skills
    messages.insert(0, @ai.system_message(content=skill_prompt))
    return
  }
}

///|
/// Loads skills from both global and local directories and applies them to the
/// provided AI messages.
///
/// Parameters:
///
/// * `self` : The loader instance to use for loading and applying skills.
/// * `messages` : The array of AI messages to modify with skill information.
pub async fn Loader::load_and_apply(
  self : Loader,
  messages : Array[@ai.Message],
) -> Unit {
  self.load()
  self.apply(messages)
}

///|
/// Retrieves all loaded skills from the loader.
///
/// Parameters:
///
/// * `self` : The loader instance containing the skills.
///
/// Returns a map where keys are skill names and values are the corresponding
/// `Skill` objects.
pub fn Loader::skills(self : Loader) -> Map[String, Skill] {
  self.skills
}
