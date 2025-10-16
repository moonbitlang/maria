///|
/// TOML Parser
pub(all) struct Parser {
  tokens : Array[Token]
  mut current : Int
  mut current_position : Position
} derive(Show)

///|
/// Create a new parser from tokens
pub fn Parser::from_tokens(tokens : Array[Token]) -> Parser {
  Parser::{
    tokens,
    current: 0,
    current_position: Position::{ line: 1, column: 1 },
  }
}

///|
/// Check if we're at the end of tokens
fn Parser::is_at_end(self : Parser) -> Bool {
  self.current >= self.tokens.length()
}

///|
/// Peek at current token
fn Parser::peek(self : Parser) -> Token {
  if self.is_at_end() {
    Token::EOF
  } else {
    self.tokens[self.current]
  }
}

///|
/// Advance to next token
fn Parser::advance(self : Parser) -> Token {
  if !self.is_at_end() {
    self.current += 1
  }
  self.previous()
}

///|
/// Get previous token
fn Parser::previous(self : Parser) -> Token {
  if self.current == 0 {
    Token::EOF
  } else {
    self.tokens[self.current - 1]
  }
}

///|
/// Skip newlines and comments
fn Parser::skip_newlines_and_comments(self : Parser) -> Unit {
  while true {
    match self.peek() {
      Newline | Comment(_) => ignore(self.advance())
      _ => break
    }
  }
}

///|
/// Parse a simple key-value pair
fn Parser::parse_key_value(
  self : Parser,
  table : TomlTable,
) -> Unit raise TomlError {
  match self.advance() {
    Identifier(name) =>
      match self.advance() {
        Equals => {
          let value = self.parse_value()
          if table.contains(name) {
            raise duplicate_key_error(self.current_position, name)
          }
          table[name] = value
        }
        _ => raise parse_error(self.current_position, "Expected '=' after key")
      }
    _ => raise parse_error(self.current_position, "Expected key")
  }
}

///|
/// Parse a value
fn Parser::parse_value(self : Parser) -> TomlValue raise TomlError {
  match self.advance() {
    StringLiteral(s) => TomlValue::String(s)
    IntegerLiteral(i) => TomlValue::Integer(i)
    FloatLiteral(f) => TomlValue::Float(f)
    BooleanLiteral(b) => TomlValue::Boolean(b)
    LeftBracket => self.parse_array()
    LeftBrace => self.parse_inline_table()
    _ => raise parse_error(self.current_position, "Expected value")
  }
}

///|
/// Parse an array
fn Parser::parse_array(self : Parser) -> TomlValue raise TomlError {
  let values : Array[TomlValue] = []
  self.skip_newlines_and_comments()
  if self.peek() == Token::RightBracket {
    ignore(self.advance())
    return TomlValue::Array(values)
  }

  // Parse first element
  values.push(self.parse_value())
  self.skip_newlines_and_comments()

  // Parse remaining elements
  while self.peek() == Token::Comma {
    ignore(self.advance()) // consume comma
    self.skip_newlines_and_comments()

    // Allow trailing comma
    if self.peek() == Token::RightBracket {
      break
    }
    values.push(self.parse_value())
    self.skip_newlines_and_comments()
  }
  if self.peek() != Token::RightBracket {
    raise parse_error(
      self.current_position,
      "Expected ']' after array elements",
    )
  }
  ignore(self.advance())
  TomlValue::Array(values)
}

///|
/// Parse an inline table
fn Parser::parse_inline_table(self : Parser) -> TomlValue raise TomlError {
  let table : TomlTable = Map::new()
  if self.peek() == Token::RightBrace {
    ignore(self.advance())
    return TomlValue::Table(table)
  }

  // Parse first key-value pair
  match self.advance() {
    Identifier(key) => {
      if self.advance() != Token::Equals {
        raise parse_error(self.current_position, "Expected '=' after key")
      }
      let value = self.parse_value()
      table[key] = value
    }
    _ =>
      raise parse_error(self.current_position, "Expected key in inline table")
  }

  // Parse remaining pairs
  while self.peek() == Token::Comma {
    ignore(self.advance()) // consume comma
    match self.advance() {
      Identifier(key) => {
        if self.advance() != Token::Equals {
          raise parse_error(self.current_position, "Expected '=' after key")
        }
        let value = self.parse_value()
        if table.contains(key) {
          raise duplicate_key_error(self.current_position, key)
        }
        table[key] = value
      }
      _ =>
        raise parse_error(self.current_position, "Expected key in inline table")
    }
  }
  if self.peek() != Token::RightBrace {
    raise parse_error(self.current_position, "Expected '}' after inline table")
  }
  ignore(self.advance())
  TomlValue::Table(table)
}

///|
/// Parse the entire TOML document
pub fn Parser::parse(self : Parser) -> TomlDocument raise TomlError {
  let root : TomlTable = Map::new()
  let mut current_table = root
  self.skip_newlines_and_comments()
  while !self.is_at_end() && self.peek() != Token::EOF {
    match self.peek() {
      LeftBracket => {
        ignore(self.advance()) // consume '['

        // Parse table name
        match self.advance() {
          Identifier(name) => {
            if self.advance() != Token::RightBracket {
              raise parse_error(
                self.current_position,
                "Expected ']' after table name",
              )
            }

            // Create or get table
            match root.get(name) {
              Some(Table(table)) => current_table = table
              Some(_) =>
                raise parse_error(
                  self.current_position,
                  "Key '\{name}' is already defined as non-table",
                )
              None => {
                let new_table : TomlTable = Map::new()
                root[name] = TomlValue::Table(new_table)
                current_table = new_table
              }
            }
          }
          _ => raise parse_error(self.current_position, "Expected table name")
        }
      }
      Identifier(_) =>
        // Key-value pair
        self.parse_key_value(current_table)
      _ =>
        raise parse_error(self.current_position, "Unexpected token in document")
    }
    self.skip_newlines_and_comments()
  }
  TomlDocument::{ root, }
}

///|
/// Parse TOML from string
pub fn parse_toml(input : String) -> TomlResult[TomlDocument] {
  try {
    let lexer = Lexer::new(input)
    let tokens = lexer.tokenize()
    let parser = Parser::from_tokens(tokens)
    let doc = parser.parse()
    Ok(doc)
  } catch {
    TomlError::LexError(pos, msg) => Err(TomlError::LexError(pos, msg))
    TomlError::ParseError(pos, msg) => Err(TomlError::ParseError(pos, msg))
    TomlError::DuplicateKey(pos, msg) => Err(TomlError::DuplicateKey(pos, msg))
    TomlError::InvalidValue(pos, msg) => Err(TomlError::InvalidValue(pos, msg))
    TomlError::UnexpectedToken(pos, expected, actual) =>
      Err(TomlError::UnexpectedToken(pos, expected, actual))
    TomlError::UnexpectedEOF(pos) => Err(TomlError::UnexpectedEOF(pos))
    TomlError::InvalidTableHeader(pos, msg) =>
      Err(TomlError::InvalidTableHeader(pos, msg))
    TomlError::InvalidArrayType(pos, msg) =>
      Err(TomlError::InvalidArrayType(pos, msg))
    _ =>
      Err(
        TomlError::ParseError(Position::{ line: 1, column: 1 }, "Unknown error"),
      )
  }
}
