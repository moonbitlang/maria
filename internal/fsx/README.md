# internal/fsx

The `internal/fsx` package provides small, focused helpers on top of
`moonbitlang/async/fs` and related modules. It offers a higher-level
API for common filesystem tasks that are frequently needed inside
maria’s agents and tooling.

## Features

- Convenience helpers for reading and writing files as UTF-8 text.
- Listing directory entries with a serializable `FileKind` enum.
- Creating directories (optionally recursive) with friendly flags.
- Inspecting filesystem metadata (stat, `mtime`, `atime`, kind checks).
- Working with temporary directories that are automatically cleaned up.
- Utilities for symbolic links (readlink) and file truncation.
- Advisory file locking helpers for coordination between processes.

## Selected APIs

- `read_file(path : StringView) -> String`
  - Read the entire file at `path` and decode it as UTF-8 text.

- `write_to_file(path : StringView, content : StringView) -> Unit`
  - Write UTF-8 text to a file, creating or truncating the file.

- `list_directory(path : StringView) -> Array[DirectoryEntry]`
  - List the entries in a directory, including their full path, name and `FileKind`.

- `make_directory(path : StringView, recursive? : Bool, exists_ok? : Bool) -> Unit`
  - Create a directory, optionally creating missing parents and ignoring
    already-existing directories.

- `stat(path : StringView) -> Stat`
  - Fetch file metadata and access modification/access timestamps via
    `Stat::mtime` and `Stat::atime`.

- `with_temporary_directory(template : String, f : async (String) -> T) -> T`
  - Create a temporary directory, run `f` with its path, and remove the
    directory afterwards.

- `readlink(path : String, bufsize? : UInt64) -> String`
  - Read the target of a symbolic link, growing the buffer as needed.

- `truncate(file : @fs.File, length : Int64) -> Unit`
  - Truncate an open file to a given byte length.

- `lock_file(file : @fs.File) -> Unit` / `get_lock_owner(file : @fs.File) -> Int?`
  - Acquire an advisory lock on a file and query its lock owner PID.

## Notes

This package is internal to maria and is optimized for clarity and
convenience over providing a full general-purpose filesystem API.
