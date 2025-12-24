///|
/// Command loader that manages and loads commands from both global and local
/// directories.
///
/// The loader searches for commands in `.moonagent/commands` directories:
///
/// - Global commands: `~/.moonagent/commands`
/// - Local commands: starting from the current working directory and walking up
///   through parent directories.
///
/// When inside a Git repo, the upward walk stops at:
///
/// - The Git repo root (directory containing `.git`)
///
/// When not inside a Git repo, no upward walk is performed; only the current
/// working directory and the user's home directory are checked.
///
/// Each command is expected to be a `.md` file with optional YAML frontmatter.
struct Loader {
  /// Logger instance for operation logging.
  logger : @pino.Logger
  /// Home directory path for global commands.
  home : String
  /// Current working directory path for local commands.
  cwd : String
  /// Map of loaded commands indexed by command name.
  commands : Map[String, Command]
}

///|
/// Creates a new command loader with the specified configuration.
///
/// Parameters:
///
/// * `home` : The home directory path for global commands. If not provided, uses
///   the system's home directory.
/// * `cwd` : The current working directory path for local commands.
/// * `logger` : The logger instance for logging operations. Defaults to a
///   console logger with the name "commands".
///
/// Returns a new `Loader` instance with an empty commands map.
///
/// Throws an error if the system's home directory cannot be determined when
/// `home` is not provided.
///
/// Example:
///
/// ```moonbit
/// let loader = @commands.Loader::new(cwd="/path/to/project")
/// ```
pub fn Loader::new(
  home? : String,
  cwd~ : String,
  logger? : @pino.Logger = @pino.logger("commands", @pino.Transport::console()),
) -> Loader raise {
  let home = match home {
    Some(home) => home
    None => @os.home()
  }
  Loader::{ home, cwd, logger, commands: {} }
}

///|
/// Loads commands from a specified directory by scanning for command definition
/// files and parsing them into the loader's command map.
///
/// Parameters:
///
/// * `self` : The loader instance to populate with discovered commands.
/// * `directory` : The directory path to scan for command files (.md files).
///
/// Throws:
///
/// This method can throw various errors during file system operations:
///
/// * File system errors when accessing directories or reading files
/// * Parsing errors when processing command definition files (these are caught
///   and logged as warnings)
async fn Loader::load_commands_from_directory(
  self : Loader,
  directory : String,
) -> Unit {
  if !@fsx.exists(directory) {
    // Directory does not exist, nothing to load. It is rather normal for user
    // to not have commands directory setup, so we just log a debug message.
    self.logger.debug(
      "Commands directory '\{directory}' does not exist, skipping.",
    )
    return
  }
  self.logger.info("Loading commands from directory '\{directory}'...")
  let entries = @fsx.list_directory(directory).filter(e => e.kind
    is @fsx.FileKind::Regular &&
    e.name.has_suffix(".md"))
  for entry in entries {
    let path = @pathx.join(directory, entry.name)
    let content = @fsx.read_file(path)
    let location = @fsx.resolve(path)
    let name = @pathx.stem(entry.name).to_string()
    let command = parse_command_from_content(content, name~, location~) catch {
      error => {
        self.logger.warn(
          "Failed to parse command in '\{path}': \{error}, skipping.",
        )
        continue
      }
    }
    self.logger.info("Loaded command '\{command.name}' from '\{path}'.")
    self.commands[command.name] = command
  }
}

///|
/// Loads commands from both global and local directories into the loader.
///
/// Parameters:
///
/// * `self` : The loader instance to populate with commands.
pub async fn Loader::load(self : Loader) -> Unit {
  self.commands.clear()
  let global_path = self.home
    |> @pathx.join(".moonagent")
    |> @pathx.join("commands")
  self.load_commands_from_directory(global_path)

  // Determine local command search roots.
  //
  // New rules:
  // 1) If `.git` exists in cwd or any ancestor, treat that directory as the repo
  //    root and load commands from cwd up to that repo root (inclusive).
  // 2) If no `.git` exists in any ancestor, load from cwd and home only.
  //
  // Precedence rule: load from the furthest directory first so closer directories
  // override earlier ones.
  // NOTE: Use canonical (realpath-resolved) paths for both `cwd` and the git
  // repo root to avoid mismatches when `cwd` contains symlinks.
  //
  // `@pathx.normalize` does not resolve symlinks, while `@fsx.resolve` does.
  // `@git.find_repo_root` internally calls `@fsx.resolve`, so we should resolve
  // `cwd` here as well; otherwise the walk-up loop may never reach `root_norm`.
  let cwd_canon = @fsx.resolve(self.cwd[:]) catch { _ => self.cwd }
  let home_canon = @fsx.resolve(self.home[:]) catch { _ => self.home }
  let cwd_norm = @pathx.normalize(cwd_canon[:])
  let home_norm = @pathx.normalize(home_canon[:])
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
      // Note: global commands (`home/.moonagent/commands`) are already loaded above,
      // so we only need to add `cwd` here (and only if it differs from home) to
      // avoid loading the same directory twice.
      if cwd_norm != home_norm {
        dirs.push(cwd_norm)
      }
  }
  for dir in dirs.rev() {
    let local_path = dir |> @pathx.join(".moonagent") |> @pathx.join("commands")
    self.load_commands_from_directory(local_path)
  }
}

///|
/// Retrieves all loaded commands from the loader.
///
/// Parameters:
///
/// * `self` : The loader instance containing the commands.
///
/// Returns a map where keys are command names and values are the corresponding
/// `Command` objects.
pub fn Loader::commands(self : Loader) -> Map[String, Command] {
  self.commands
}

///|
/// Get a specific command by name.
///
/// Parameters:
///
/// * `self` : The loader instance.
/// * `name` : The command name to retrieve.
///
/// Returns the command if found, None otherwise.
pub fn Loader::get_command(self : Loader, name : String) -> Command? {
  self.commands.get(name)
}
