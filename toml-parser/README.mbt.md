# TOML Parser for MoonBit

A TOML (Tom's Obvious, Minimal Language) parser implementation in MoonBit.

## Features

- Parse TOML documents into a structured AST
- Support for basic TOML types: strings, integers, floats, booleans, arrays, tables
- Error handling with position information
- Type-safe access to parsed values
- Comprehensive test suite

## Usage

### Basic Parsing

```moonbit
///|
test "basic usage example" {
  let toml_content =
    #|title = "TOML Example"
    #|
    #|[owner]
    #|name = "Tom Preston-Werner"
    #|organization = "GitHub"
    #|
    #|[database]
    #|server = "192.168.1.1"
    #|ports = [ 8001, 8002, 8003 ]
    #|connection_max = 5000
    #|enabled = true
    #|
  let result = parse_toml(toml_content)
  match result {
    Ok(doc) => {
      // Access values using dot notation
      inspect(doc.get("title"), content="Some(String(\"TOML Example\"))")

      // Access nested values  
      match doc.get("owner") {
        Some(TomlValue::Table(owner_table)) =>
          inspect(
            owner_table.get("name"),
            content="Some(String(\"Tom Preston-Werner\"))",
          )
        _ => assert_eq(true, false)
      }

      // Access database configuration
      match doc.get("database") {
        Some(TomlValue::Table(db_table)) => {
          inspect(
            db_table.get("server"),
            content="Some(String(\"192.168.1.1\"))",
          )
          inspect(db_table.get("connection_max"), content="Some(Integer(5000))")
          inspect(db_table.get("enabled"), content="Some(Boolean(true))")
        }
        _ => assert_eq(true, false)
      }
    }
    Err(error) => {
      println("Parse error: \{error}")
      assert_eq(true, false)
    }
  }
}
```

### Type-Safe Value Access

```moonbit
///|
test "type safe access" {
  let toml = "name = \"MoonBit\""
  let result = parse_toml(toml)
  match result {
    Ok(doc) =>
      // Safe string access
      match doc.get("name") {
        Some(value) =>
          match value.as_string() {
            Some(name) => inspect(name, content="MoonBit")
            None => assert_eq(true, false)
          }
        None => assert_eq(true, false)
      }
    Err(_) => assert_eq(true, false)
  }
}
```

## API Reference

### Core Types

- `TomlValue` - Represents any TOML value (String, Integer, Float, Boolean, Array, Table)
- `TomlDocument` - Root document containing a table of key-value pairs
- `TomlTable` - Type alias for `Map[String, TomlValue]`
- `TomlError` - Error types with position information

### Main Functions

- `parse_toml(input: String) -> TomlResult[TomlDocument]` - Parse TOML string
- `TomlDocument::get(key: String) -> TomlValue?` - Get value by key
- `TomlValue::as_string() -> String?` - Safe string extraction
- `TomlValue::as_integer() -> Int64?` - Safe integer extraction
- `TomlValue::as_table() -> TomlTable?` - Safe table extraction

## Error Handling

The parser provides detailed error information:

```moonbit
///|
test "error handling example" {
  let invalid_toml = "invalid syntax here"
  let result = parse_toml(invalid_toml)
  match result {
    Ok(_) => assert_eq(true, false) // Should not succeed
    Err(error) =>
      // Error contains position and message information
      inspect(
        error,
        content=(
          #|ParseError({line: 1, column: 1}, "Expected '=' after key")
        ),
      )
  }
}
```

## Supported TOML Features

- ✅ Basic key-value pairs
- ✅ Strings with escape sequences  
- ✅ Integers (with underscores)
- ✅ Floats (basic support)
- ✅ Booleans (true/false)
- ✅ Arrays
- ✅ Tables [table.name]
- ✅ Inline tables { key = value }
- ❌ Multi-line strings (not yet implemented)
- ❌ Array of tables [[table]] (not yet implemented)
- ❌ DateTime values (not yet implemented)

## Implementation Details

The parser is implemented using a two-stage approach:

1. **Lexer** - Converts input string into tokens
2. **Parser** - Converts tokens into structured AST

This provides good error reporting and makes the parser extensible for future TOML features.