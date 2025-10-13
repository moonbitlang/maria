# `moonbitlang/maria/tool/list_files`

Lists files in a directory with detailed metadata.

## Overview

This tool provides enhanced directory listing with file type information, size metadata, and statistics. It helps AI agents explore and understand project structure.

## Parameters

- `path` (required): Directory path to list files from (relative to working directory)

## Behavior

Returns detailed information about each entry:
- **name**: File or directory name
- **kind**: Type of entry ("file", "directory", "symlink", etc.)
- **size**: File size in bytes (None for directories)
- **is_hidden**: Whether the entry is hidden (starts with '.')

Also provides aggregate statistics:
- **total_count**: Total number of entries
- **file_count**: Number of regular files
- **directory_count**: Number of directories

## Use Cases

- Exploring project structure
- Finding specific file types
- Understanding directory contents
- Analyzing project organization
- Identifying hidden files
- Getting file size information

## Notes

- Part of the maria AI agent tool system
- Provides richer metadata than basic directory listing
- Distinguishes between files, directories, and symlinks
- Includes hidden file detection
- Returns structured JSON for easy parsing
