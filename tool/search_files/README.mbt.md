# `moonbitlang/maria/tool/search_files`

Searches files with regex patterns or MoonBit symbol lookups.

## Overview

This tool provides powerful file search capabilities including regex pattern matching, MoonBit definition lookup, and reference finding. Essential for code navigation and analysis.

## Parameters

- `query` (required): Search pattern or symbol name
- `kind` (required): Type of search
  - `"regex"`: Regular expression pattern search
  - `"moonbit_definition"`: Find MoonBit symbol definitions
  - `"moonbit_references"`: Find all references to a MoonBit symbol
- `path` (optional): Directory or file to search in
- `include_patterns` (optional): File patterns to include (e.g., ["*.mbt"])
- `exclude_patterns` (optional): File patterns to exclude

## Search Types

### Regex Search
- Searches file contents using regular expressions
- Returns matching lines with context
- Supports PCRE2 regex syntax

### MoonBit Definition Search
- Finds where a MoonBit symbol is defined
- Works with functions, types, variables, etc.
- Uses MoonBit's built-in analysis

### MoonBit References Search
- Finds all usages of a MoonBit symbol
- Helps understand symbol dependencies
- Shows where code is called or referenced

## Result Format

Each match includes:
- `path`: File path where match was found
- `line_number`: Line number of the match
- `match_line`: The actual line content
- `context`: Surrounding lines for context

## Use Cases

- Finding function definitions
- Searching for specific patterns in code
- Understanding code dependencies
- Refactoring assistance
- Code navigation
- Symbol usage analysis

## Notes

- Part of the maria AI agent tool system
- Integrates with MoonBit's language server for symbol analysis
- Supports both text-based and semantic search
- Returns structured results with line numbers and context
