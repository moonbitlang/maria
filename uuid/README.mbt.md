# `moonbitlang/maria/uuid`

UUID (Universally Unique Identifier) generation and parsing following RFC 9562.

## Overview

This package provides UUID generation, parsing, and manipulation capabilities with support for UUID v4 (random) and complete RFC 9562 variant/version detection.

## Usage

### Generate UUID v4

```moonbit
///|
test "generate uuid v4" {
  let uuid = @uuid.v4()
  let uuid_str = uuid.to_string()
  // UUID format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  @json.inspect(uuid_str.length(), content=36)
  @json.inspect(uuid.version(), content=Some(@uuid.Version::V4))
}
```

### Parse UUID from String

```moonbit
///|
test "parse uuid" {
  let uuid = @uuid.parse("550e8400-e29b-41d4-a716-446655440000")
  @json.inspect(uuid.to_string(), content="550e8400-e29b-41d4-a716-446655440000")
}
```

### Special UUIDs

```moonbit
///|
test "special uuids" {
  // Nil UUID (all zeros)
  @json.inspect(@uuid.nil.to_string(), content="00000000-0000-0000-0000-000000000000")
  
  // Max UUID (all ones)
  @json.inspect(@uuid.max.to_string(), content="ffffffff-ffff-ffff-ffff-ffffffffffff")
}
```

### Convert to Bytes

```moonbit
///|
test "uuid to bytes" {
  let uuid = @uuid.nil
  let bytes = uuid.to_bytes()
  @json.inspect(bytes.length(), content=16)
}
```

## API Reference

### Functions

#### `v4() -> Uuid raise`

Generates a random UUID version 4.

#### `parse(hex: StringView) -> Uuid raise ParseError`

Parses a UUID from a hexadecimal string representation.

- **Parameters:**
  - `hex`: String in format "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
- **Raises:** `ParseError` if the string is invalid

### Types

#### `Uuid`

The UUID type representing a 128-bit identifier.

**Methods:**
- `to_string() -> String`: Returns the canonical string representation
- `to_bytes() -> Bytes`: Returns the 16-byte binary representation
- `variant() -> Variant`: Returns the UUID variant
- `version() -> Version?`: Returns the UUID version (if RFC9562)

#### `Variant`

Enum representing UUID variants:
- `ReservedNCS`: Reserved for NCS compatibility
- `RFC9562(Version)`: Standard RFC 9562 UUID with version
- `ReservedMicrosoft`: Reserved for Microsoft compatibility
- `ReservedFuture`: Reserved for future definition

#### `Version`

Enum representing UUID versions (V0-V15).

### Constants

- `nil`: The nil UUID (all zeros)
- `max`: The max UUID (all ones)

### Errors

#### `ParseError`

Raised when parsing invalid UUID strings:
- `UnexpectedEnd`: String ended unexpectedly
- `InvalidOctet(StringView)`: Invalid hexadecimal character
- `MissingDash(StringView)`: Expected dash separator missing
- `ExtraContent(StringView)`: Unexpected content after UUID
