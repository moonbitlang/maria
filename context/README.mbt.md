# `moonbitlang/maria/context`

Context extraction and management for AI conversations.

## Overview

This package provides utilities for extracting relevant code snippets and managing context windows for AI conversations.

## Usage

### Creating an Extractor

```moonbit
///|
test "create extractor" {
  let extractor = @context.Extractor::new(
    window_size=8000,
    overlap=1000
  )
  let _ = extractor
}
```

### Extracting Code Snippets

```moonbit
///|
test "extract snippets" {
  let extractor = @context.Extractor::new()
  let code = "// Large code file content..."
  let history = [/* conversation history */]
  
  let snippets = extractor.extract_code_snippets(code, history~)
  // Returns relevant code segments based on conversation
  let _ = snippets
}
```

## API Reference

### Types

#### `Extractor`

Extracts relevant code snippets for AI context.

**Methods:**
- `new(window_size?: Int, overlap?: Int) -> Extractor`: Creates extractor
- `extract_code_snippets(content: String, history~: Array[ChatCompletionMessageParam]) -> String?`: Extracts relevant snippets

### Features

- Smart code snippet extraction
- Context window management
- Sliding window with overlap
- Relevance ranking based on conversation
- Token counting integration

## Notes

- Used to manage large codebases in AI conversations
- Prevents context window overflow
- Maintains relevant code in focus
- Integrates with token counting
