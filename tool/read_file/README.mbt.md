# `moonbitlang/maria/tool/read_file`

Reads file contents or lists directory entries.

## Overview

This tool allows AI agents to read file contents with optional line range filtering, or list directory contents. It's a versatile file system inspection tool.

## Parameters

- `path` (required): Path to the file or directory to read
- `start_line` (optional): Starting line number for partial file reads (1-indexed)
- `end_line` (optional): Ending line number for partial file reads

## Behavior

### Reading Files

- Returns the complete file content by default
- Supports reading specific line ranges with `start_line` and `end_line`
- Includes the actual path, content, and line range in the result
- Useful for inspecting large files without loading everything

### Reading Directories

- If path is a directory, lists all entries
- Returns entry names and a formatted display string
- Helps agents explore file system structure

## Use Cases

- Reading configuration files
- Inspecting code files
- Reading specific sections of large files
- Exploring directory structure
- Viewing log file snippets

## Notes

- Part of the maria AI agent tool system
- Supports both files and directories
- Line numbers are 1-indexed (not 0-indexed)
- Efficient for large files with line range filtering
