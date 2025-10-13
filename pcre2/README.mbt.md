# `moonbitlang/maria/pcre2`

PCRE2 (Perl Compatible Regular Expressions 2) bindings for pattern matching.

## Overview

This package provides bindings to the PCRE2 library for advanced regular expression matching and replacement operations.

## Usage

### Basic Pattern Matching

```moonbit
///|
test "match pattern" {
  let pattern = @pcre2.compile("\\d+")
  let result = pattern.match_("The answer is 42")
  // Returns match result with captured groups
  let _ = result
}
```

### Pattern Replacement

```moonbit
///|
test "replace pattern" {
  let pattern = @pcre2.compile("\\d+")
  let result = pattern.replace("Price: 100", "200")
  // result might be "Price: 200"
  let _ = result
}
```

## API Reference

### Functions

#### `compile(pattern: String) -> Pattern raise`

Compiles a regular expression pattern.

- **Parameters:**
  - `pattern`: PCRE2-compatible regular expression string
- **Returns:** Compiled pattern object
- **Raises:** Compilation errors for invalid patterns

### Types

#### `Pattern`

A compiled regular expression pattern.

**Methods:**
- `match_(text: String) -> MatchResult?`: Finds first match
- `replace(text: String, replacement: String) -> String`: Replaces matches

## Pattern Syntax

PCRE2 supports:
- Basic patterns: `.` `*` `+` `?` `[]` `()`
- Character classes: `\d` `\w` `\s` `\D` `\W` `\S`
- Anchors: `^` `$` `\b` `\B`
- Quantifiers: `{n}` `{n,}` `{n,m}`
- Groups: `()` `(?:)` `(?<name>)`
- Lookahead/lookbehind: `(?=)` `(?!)` `(?<=)` `(?<!)`

## Notes

- PCRE2 library is included in the package
- Patterns are compiled once and can be reused
- Supports Unicode and UTF-8
- More powerful than basic regex engines
- Full PCRE2 documentation available at https://pcre2project.github.io/pcre2/
