# `moonbitlang/maria/tool/write_to_file`

Writes or replaces content in files with pattern matching support.

## Overview

This tool allows AI agents to write new files, update existing files, or replace specific patterns in files. It supports both full file replacement and targeted pattern-based replacement.

## Parameters

- `path` (required): The file path to write to
- `content` (required): The new content to write
- `old_content` (optional): Pattern to search for and replace
- `create_directories` (optional): Whether to create parent directories (default: true)

## Behavior

### Creating New Files

- If file doesn't exist, creates it with the content
- Parent directories are created automatically if `create_directories` is true

### Updating Files

- If `old_content` is provided, searches for and replaces that pattern
- Supports exact string matching for targeted replacements
- Useful for updating specific sections without rewriting the entire file

### Full Replacement

- If `old_content` is not provided, replaces entire file content
- Returns operation type: "created", "updated", or "replaced"

## Use Cases

- Creating new source files
- Updating configuration files
- Replacing specific code sections
- Refactoring code with pattern replacement
- Generating files from templates

## Notes

- Part of the maria AI agent tool system
- Pattern matching is exact (not regex)
- Returns detailed result including operation type and file path
- Preserves file system structure
