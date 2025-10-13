# `moonbitlang/maria/git`

Git version control operations wrapper.

## Overview

This package provides high-level functions for common Git operations like cloning, initializing repositories, committing changes, creating branches, and generating diffs.

## Usage

### Cloning a Repository

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("git-clone")
  g.add_defer(() => dir.close())
  
  @git.clone(
    "https://github.com/example/repo.git",
    to="repo",
    cwd=dir.path()
  )
})
```

### Initializing a Repository

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("git-init")
  g.add_defer(() => dir.close())
  
  let repo_path = @path.join(dir.path(), "my-repo")
  @git.init_(repo_path)
})
```

### Committing Changes

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("git-commit")
  g.add_defer(() => dir.close())
  
  @git.init_(dir.path())
  let _ = dir.add_file("test.txt", "Hello")
  
  @git.commit(
    "Initial commit",
    ["test.txt"],
    cwd=dir.path()
  )
})
```

### Creating a Branch

```moonbit
@async.with_task_group(g => {
  let dir = @mock.directory("git-branch")
  g.add_defer(() => dir.close())
  
  @git.init_(dir.path())
  let msg = @git.create_branch(branch_name="feature", cwd=dir.path())
  let _ = msg
})
```

### Generating Diffs

```moonbit
let original = "Hello, World!"
let modified = "Hello, Moon!"

let diff = @git.generate_git_diff(original~, modified~)
// diff contains unified diff format
let _ = diff
```

## API Reference

### Functions

#### `clone(url: String, to~: StringView, cwd?: StringView) -> Unit`

Clones a Git repository.

- **Parameters:**
  - `url`: Repository URL to clone
  - `to`: Destination directory name
  - `cwd`: Working directory for the operation
- **Raises:** Fails if clone operation returns non-zero exit status

#### `init_(path: String, output?: &Logger) -> Unit`

Initializes a new Git repository.

- **Parameters:**
  - `path`: Path where to initialize the repository
  - `output`: Optional logger for command output
- **Raises:** Fails if init operation returns non-zero exit status

#### `commit(message: StringView, files: Array[StringView], output?: &Logger, cwd?: StringView) -> Unit`

Stages and commits files.

- **Parameters:**
  - `message`: Commit message
  - `files`: Array of file paths to add and commit
  - `output`: Optional logger for command output
  - `cwd`: Working directory
- **Raises:** Fails if add or commit operations fail

#### `create_branch(branch_name~: String, cwd?: String) -> String`

Creates a new Git branch.

- **Parameters:**
  - `branch_name`: Name of the branch to create
  - `cwd`: Working directory
- **Returns:** Success message
- **Raises:** Fails if branch creation fails

#### `generate_git_diff(original~: String, modified~: String) -> String`

Generates a unified diff between two text strings.

- **Parameters:**
  - `original`: Original text content
  - `modified`: Modified text content
- **Returns:** Unified diff output

## Notes

- All operations are asynchronous
- Git must be installed and available in the system PATH
- Operations fail with descriptive error messages on non-zero exit codes
- Diffs are generated using `git diff --no-index` in a temporary directory
