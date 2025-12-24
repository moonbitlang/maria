# Commands Subsystem

The commands subsystem provides a simple way to load and manage natural language command templates for the maria agent framework. Commands are stored as markdown files that the AI agent can read and interpret directly.

## Overview

The commands subsystem is intentionally simple:

1. **Command** (`command.mbt`) - Represents command content loaded from markdown files
2. **Loader** (`loader.mbt`) - Loads and manages commands from `.moonagent/commands` directories

**Key Design Principle**: Commands contain natural language instructions that the AI interprets directly. There is **no parsing or templating** - the AI agent reads the command content and understands what to do naturally.

## Features

- ✅ Load commands from global (`~/.moonagent/commands`) and local `.moonagent/commands` directories, walking up to the git repo root when available
- ✅ YAML frontmatter for command metadata (description)
- ✅ Command listing and introspection
- ✅ Simple error handling
- ✅ Natural language content - no template syntax required

## Directory Structure

Commands are stored in `.moonagent/commands` directories:

```plaintext
~/.moonagent/commands/          # Global commands
  greet.md
  deploy.md

./project/.moonagent/commands/  # Repo-root commands
  build.md
  test.md

./project/sub/.moonagent/commands/  # Nested commands (override repo root)
  lint.md
```

## Command File Format

Commands are markdown files with optional YAML frontmatter:

```markdown
---
description: "Greet the user warmly"
---

Please greet the user warmly and ask how you can help them today.
Be friendly and professional.
```

### Frontmatter Fields

- `description` (optional): A brief description of what the command does

### Content

The markdown content after the frontmatter contains natural language instructions for the AI. The AI reads and interprets these instructions directly.

## Usage

### Basic Example

```moonbit
// Create a loader
let loader = Loader::new(cwd="/path/to/project")

// Load commands from global and local directories
loader.load()

// List available commands
let commands = loader.commands()
// Returns: {
//  "greet": { ... },
//  "deploy": { ... },
//  "build": { ... },
//  "test": { ... },
// }

// Get a specific command
let cmd = loader.get_command("greet")
// Returns: Some(Command {
//   name: "greet",
//   description: Some("Greet the user warmly"),
//   content: "Please greet the user warmly...",
//   location: "/path/to/greet.md"
// })
```

### Using Command Content

Once loaded, the command's content can be provided to the AI agent:

```moonbit
match loader.get_command("greet") {
  Some(cmd) => {
    // Pass cmd.content to the AI agent
    // The AI reads and interprets the natural language instructions
    ai_agent.process(cmd.content)
  }
  None => println("Command not found")
}
```

## Loader API

### Constructor

```moonbit
pub fn Loader::new(
  home? : String,
  cwd~ : String,
  logger? : @pino.Logger
) -> Loader raise
```

Creates a new command loader. If `home` is not provided, uses system home directory.

### Loading Commands

```moonbit
pub async fn Loader::load(self : Loader) -> Unit
```

Loads commands from global `.moonagent/commands` and local `.moonagent/commands`
directories. When the current working directory is inside a git repo, the
loader walks up to the repo root and loads `.moonagent/commands` at each level,
with nearer directories overriding earlier ones.

### Introspection

```moonbit
// Get specific command
pub fn Loader::get_command(self : Loader, name : String) -> Command?

// Get all commands
pub fn Loader::commands(self : Loader) -> Map[String, Command]
```

## Command Structure

```moonbit
pub struct Command {
  name : String           // Command name (from filename)
  description : String?   // Optional description from frontmatter
  content : String        // Natural language content
  location : String       // File path
}
```

## Examples

### Example 1: Simple Greeting Command

**File**: `.moonagent/commands/greet.md`

```markdown
---
description: "Greet the user warmly"
---

Please greet the user in a warm and friendly manner. Ask how you can help them today.
```

### Example 2: Deployment Command

**File**: `.moonagent/commands/deploy.md`

```markdown
---
description: "Help deploy an application"
---

Help the user deploy their application. Ask them about:
- Which environment (staging, production, etc.)
- What version they want to deploy
- Any special configuration or considerations

Then guide them through the deployment process step by step.
```

### Example 3: Code Review Command

**File**: `.moonagent/commands/review.md`

```markdown
---
description: "Review code for best practices"
---

Review the user's code with focus on:
1. Code quality and readability
2. Best practices for the language/framework
3. Potential bugs or issues
4. Performance considerations
5. Security concerns

Provide constructive feedback with specific examples and suggestions.
```

## Error Handling

### CommandFormatError

Raised when command file has invalid frontmatter:

```moonbit
// Invalid frontmatter in command file
// ---
// description: 123  # Should be string
// ---
// This will be logged as a warning and skipped during loading
```

Commands with invalid frontmatter are skipped during loading and a warning is logged.

## Testing

The subsystem includes comprehensive tests:

- **Command tests** (`command.mbt`) - 2 test cases for parsing
- **Loader tests** (`loader_test.mbt`) - 10 test cases covering loading and listing

Run tests with:

```bash
moon test internal/commands
```

## Design Philosophy

### Why No Templating?

The original design included command parsing and templating (similar to the TypeScript reference). However, this was removed because:

1. **Natural language is more flexible** - AI can interpret instructions better than rigid templates
2. **Simpler implementation** - Less code to maintain and debug
3. **More powerful** - AI understanding > string interpolation
4. **Easier to write** - Users write natural instructions, not template syntax

### Comparison with TypeScript Reference

The TypeScript reference (`/Users/haoxiang/Workspace/moonbit/agent/src/commands`) includes:

- ❌ Command query parser - Not needed, AI understands natural language
- ❌ Template processor (nunjucks) - Not needed, AI interprets instructions directly
- ✅ Command file loader - Core functionality, implemented
- ✅ Support for global and local commands - Implemented
- ✅ Command listing API - Implemented

## Integration Example

Here's how the commands subsystem can be integrated into the maria agent:

```moonbit
// In agent initialization
let commands_loader = @commands.Loader::new(cwd=project_path)
commands_loader.load()

// Make commands available to AI
let available_commands = commands_loader.commands()
// Show in system prompt: "Available commands: greet, deploy, review..."

// When user requests a command
match commands_loader.get_command(command_name) {
  Some(cmd) => {
    // Inject command content into conversation
    // AI reads and interprets the natural language instructions
    messages.push(Message::User(cmd.content))
  }
  None => println("Command '\{command_name}' not found")
}
```

## Future Enhancements

Potential improvements:

- [ ] Command categories/tags for organization
- [ ] Command dependencies (one command can reference others)
- [ ] Command validation and linting
- [ ] Interactive command discovery UI
- [ ] Command usage analytics

## License

Part of the maria agent framework.
