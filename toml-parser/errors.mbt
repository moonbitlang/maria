///|
/// TOML parsing errors with position information
pub(all) suberror TomlError {
  LexError(Position, String)
  ParseError(Position, String)
  DuplicateKey(Position, String)
  InvalidValue(Position, String)
  UnexpectedToken(Position, String, String) // position, expected, actual
  UnexpectedEOF(Position)
  InvalidTableHeader(Position, String)
  InvalidArrayType(Position, String)
} derive(Show, Eq, ToJson)

///|
/// Result type for TOML operations
pub typealias Result[T, TomlError] as TomlResult[T]

///|
/// Helper functions for creating errors
pub fn lex_error(pos : Position, msg : String) -> TomlError {
  TomlError::LexError(pos, msg)
}

///|
pub fn parse_error(pos : Position, msg : String) -> TomlError {
  TomlError::ParseError(pos, msg)
}

///|
pub fn duplicate_key_error(pos : Position, key : String) -> TomlError {
  TomlError::DuplicateKey(pos, "Duplicate key: \{key}")
}

///|
pub fn invalid_value_error(pos : Position, msg : String) -> TomlError {
  TomlError::InvalidValue(pos, msg)
}

///|
pub fn unexpected_token_error(
  pos : Position,
  expected : String,
  actual : String,
) -> TomlError {
  TomlError::UnexpectedToken(pos, expected, actual)
}

///|
pub fn unexpected_eof_error(pos : Position) -> TomlError {
  TomlError::UnexpectedEOF(pos)
}

///|
pub fn invalid_table_header_error(pos : Position, msg : String) -> TomlError {
  TomlError::InvalidTableHeader(pos, msg)
}

///|
pub fn invalid_array_type_error(pos : Position, msg : String) -> TomlError {
  TomlError::InvalidArrayType(pos, msg)
}
