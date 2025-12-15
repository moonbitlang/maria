# AGENTS.md - internal/openrouter Package

This document describes the conventions and patterns used in the `internal/openrouter` package for defining types and implementing JSON serialization.

## Type Definition Conventions

### 1. File Organization

- Each type is defined in its own file, named with snake_case matching the type name
- Files are organized per directory as MoonBit packages
- Code is organized in blocks separated by `///|`, with block order being irrelevant
- Example: `UserMessage` type is in `user_message.mbt`, `ChatMessageContentItem` is in `chat_message_content_item.mbt`

### 2. Using `enum` for Union Types

**Convention**: Use `enum` to express the concept of union types (sum types). Each enum variant can either:

- Wrap a struct type with additional fields (e.g., `Text(ChatMessageContentItemText)`)
- Be a simple tag without data (e.g., `FiveMinutes`, `OneHour`)
- Wrap a primitive type (e.g., `Text(String)`)

**Examples**:

```moonbit
// Union of different message types
enum Message {
  System(SystemMessage)
  User(UserMessage)
  Developer(MessageDeveloper)
  Assistant(AssistantMessage)
  Tool(ToolResponseMessage)
}

// Union of string or array
enum UserMessageContent {
  Text(String)
  Items(Array[ChatMessageContentItem])
}

// Simple enum with tag-only variants
enum Ttl {
  FiveMinutes
  OneHour
}

// Mixed: some variants with data, some without
enum ChatGenerationParamsPlugin {
  Moderation
  Web(ChatGenerationParamsPluginWeb)
  FileParser(ChatGenerationParamsPluginFileParser)
  ResponseHealing(ChatGenerationParamsPluginResponseHealing)
}
```

### 3. Using `struct` for Product Types

**Convention**: Use `struct` for types with named fields. Use `?` suffix for optional fields.

**Examples**:

```moonbit
// Simple struct with required and optional fields
struct UserMessage {
  content : UserMessageContent
  name : String?
}

// Struct with many optional fields
struct ChatGenerationParams {
  provider : ChatGenerationParamsProvider?
  plugins : Array[ChatGenerationParamsPlugin]?
  route : ChatGenerationParamsRoute?
  messages : Array[Message]
  model : String?
  stream : Bool
  temperature : Float?
}
```

## ToJson Implementation Conventions

### 1. ToJson for Struct Types

**Pattern**: Always create a `Map[String, Json]` first, add fields to it, then convert to JSON.

**Steps**:

1. Create a mutable map with `let object : Map[String, Json] = { ... }`
2. Initialize required fields in the map literal (especially "type" discriminator if needed)
3. Conditionally add optional fields using pattern matching with `if field is Some(value)`
4. Return `Json::object(object)` or `object.to_json()`

**Examples**:

```moonbit
// Struct with optional fields
pub impl ToJson for UserMessage with to_json(self : UserMessage) -> Json {
  let object : Map[String, Json] = { "role": "user" }
  if self.name is Some(name) {
    object["name"] = name.to_json()
  }
  object["content"] = self.content.to_json()
  Json::object(object)
}

// Struct with type discriminator
pub impl ToJson for ChatMessageContentItemText with to_json(
  self : ChatMessageContentItemText,
) -> Json {
  let object : Map[String, Json] = {
    "type": "text",
    "text": self.text.to_json(),
  }
  if self.cache_control is Some(cache_control) {
    object["cache_control"] = cache_control.to_json()
  }
  object.to_json()
}

// Struct with only type discriminator and optional fields
pub impl ToJson for ChatMessageContentItemCacheControlEphemeral with to_json(
  self : ChatMessageContentItemCacheControlEphemeral,
) -> Json {
  let object : Map[String, Json] = { "type": "ephemeral" }
  if self.ttl is Some(ttl) {
    object["ttl"] = ttl.to_json()
  }
  object.to_json()
}
```

**Key Points**:

- Use `: Map[String, Json]` type annotation when creating the map
- The `"type"` field is usually included for polymorphic types (type discriminator)
- Optional fields use `if field is Some(value)` pattern
- Always call `.to_json()` on field values to recursively serialize
- Can use either `Json::object(object)` or `object.to_json()` to finalize

### 2. ToJson for Enum Types

**Pattern**: Use simple pattern matching to dispatch to the appropriate variant. The enum ToJson should be a simple dispatcher that delegates to inner types.

**Convention**: The `"type"` discriminator field is **delegated to the inner type**, not added by the enum's ToJson implementation. The enum merely dispatches.

**Examples**:

```moonbit
// Simple dispatch - no type field added here
pub impl ToJson for UserMessageContent with to_json(self : UserMessageContent) -> Json {
  match self {
    Text(text) => text.to_json()
    Items(items) => items.to_json()
  }
}

// Single-variant enum still uses match for consistency
pub impl ToJson for ChatMessageContentItem with to_json(
  self : ChatMessageContentItem,
) -> Json {
  match self {
    Text(text) => text.to_json()
  }
}

// Enum dispatching to wrapped types
pub impl ToJson for ChatMessageContentItemCacheControl with to_json(
  self : ChatMessageContentItemCacheControl,
) -> Json {
  match self {
    Ephemeral(ephemeral) => ephemeral.to_json()
  }
}

// Simple string enum returns string literals directly
pub impl ToJson for Ttl with to_json(self : Ttl) -> Json {
  match self {
    FiveMinutes => "5m"
    OneHour => "1h"
  }
}
```

**Key Points**:

- Enum's ToJson is always a simple `match` expression that delegates
- The enum does **not** wrap the result or add any fields
- Type discriminators (like `"type": "text"`) are added by the **inner struct**, not the enum
- For enums with string-like variants (e.g., `Ttl`), directly return string literals
- The pattern keeps responsibility clear: enums dispatch, structs build objects

### 3. Visibility

**Convention**: ToJson implementations are marked with `pub` to make them public, allowing external packages to serialize these types.

```moonbit
pub impl ToJson for UserMessage with to_json(self : UserMessage) -> Json {
  // ...
}
```

## Additional Guidelines

### 1. Type Naming Conventions

- Use PascalCase for type names
- Prefix related types with a common base name for grouping:
  - `ChatGenerationParams`, `ChatGenerationParamsProvider`, `ChatGenerationParamsPlugin`
  - `ChatMessageContentItem`, `ChatMessageContentItemText`, `ChatMessageContentItemCacheControl`
- Enum variants follow PascalCase as well

### 2. JSON Field Naming

- JSON field names use snake_case (e.g., `"tool_call_id"`, `"cache_control"`)
- Field names in structs also use snake_case to match
- Type discriminator is always called `"type"` when present

### 3. Working with Optional Fields

- Use `?` suffix on field types for optional fields: `name : String?`
- Check optional fields with `if field is Some(value)` pattern
- Only add optional fields to JSON object if they are `Some`
- This keeps the JSON clean without null values for absent fields

### 4. Recursive Serialization

- Always call `.to_json()` on nested types
- Let the type system handle the recursion through each type's ToJson implementation
- Arrays and Maps have built-in ToJson implementations

### 5. Testing

- Use `moon test` to run tests
- Use snapshot testing with `inspect` for ToJson implementations
- Run `moon test --update` to update snapshots when behavior changes
- Check test files ending in `_test.mbt` for examples

### 6. Code Formatting and Checking

- Run `moon fmt` to format code properly before committing
- Run `moon info` to update the `.mbti` interface file
- Check `.mbti` diffs to verify public API changes
- Run `moon check` to lint the code

### 7. Common Patterns Summary

**For a struct with optional fields and type discriminator**:

```moonbit
pub impl ToJson for MyStruct with to_json(self : MyStruct) -> Json {
  let object : Map[String, Json] = {
    "type": "my_struct",
    "required_field": self.required_field.to_json(),
  }
  if self.optional_field is Some(value) {
    object["optional_field"] = value.to_json()
  }
  object.to_json()
}
```

**For an enum that dispatches**:

```moonbit
pub impl ToJson for MyEnum with to_json(self : MyEnum) -> Json {
  match self {
    Variant1(data) => data.to_json()
    Variant2(data) => data.to_json()
    SimpleVariant => "simple_value"
  }
}
```

**For an enum with simple string values**:

```moonbit
pub impl ToJson for Status with to_json(self : Status) -> Json {
  match self {
    Active => "active"
    Inactive => "inactive"
    Pending => "pending"
  }
}
```

## Working with This Package

1. When adding new types, create a new `.mbt` file with the type name in snake_case
2. Define the type (struct or enum) in a `///|` block
3. Implement `ToJson` in another `///|` block following the conventions above
4. Run `moon info && moon fmt` to update interface and format code
5. Run `moon test` to verify tests pass
6. Check the `.mbti` diff to ensure the public API is as expected

## Example Workflow

```bash
# After editing files
moon info && moon fmt

# Check for errors
moon check

# Run tests
moon test

# If behavior changed intentionally
moon test --update

# Check coverage
moon coverage analyze > uncovered.log
```
