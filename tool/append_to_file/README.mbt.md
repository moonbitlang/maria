# `moonbitlang/maria/tool/append_to_file`

Appends content to files, creating them if they don't exist.

## Overview

This tool allows AI agents to append content to existing files or create new files with the specified content. It automatically creates any necessary parent directories.

## Parameters

- `content` (required): The content to append to the file
- `path` (optional): The file path relative to the working directory
- `separator` (optional): A separator to add before the appended content

## Behavior

- If the file exists, content is appended to the end
- If the file doesn't exist, it is created with the content
- Parent directories are created automatically if needed
- Optional separator can be added before the new content (e.g., newline, comma)

## Use Cases

- Adding log entries to files
- Appending data to CSV or text files
- Building files incrementally
- Adding entries to configuration files

## Notes

- Part of the maria AI agent tool system
- Registered automatically with the agent
- Returns the path of the modified/created file
