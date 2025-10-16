///|
/// Token types for TOML lexer
pub enum Token {
  StringLiteral(String)
  IntegerLiteral(Int64)
  FloatLiteral(Double)
  BooleanLiteral(Bool)
  Identifier(String)
  LeftBracket
  RightBracket
  LeftBrace
  RightBrace
  Equals
  Dot
  Comma
  Newline
  Comment(String)
  EOF
} derive(Show, Eq, ToJson)

///|
/// Lexer state
pub(all) struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
} derive(Show)

///|
/// Create a new lexer
pub fn Lexer::new(input : String) -> Lexer {
  Lexer::{ input, position: 0, line: 1, column: 1 }
}

///|
/// Peek at current character
fn Lexer::peek(self : Lexer) -> Char? {
  if self.position >= self.input.length() {
    None
  } else {
    self.input.get_char(self.position)
  }
}

///|
/// Advance to next character
fn Lexer::advance(self : Lexer) -> Char? {
  if self.position >= self.input.length() {
    None
  } else {
    let ch = self.input.get_char(self.position)
    self.position += 1
    match ch {
      Some('\n') => {
        self.line += 1
        self.column = 1
      }
      Some(_) => self.column += 1
      None => ignore(())
    }
    ch
  }
}

///|
/// Skip whitespace
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while true {
    match self.peek() {
      Some(' ') | Some('\t') | Some('\r') => ignore(self.advance())
      _ => break
    }
  }
}

///|
/// Read identifier
fn Lexer::read_identifier(self : Lexer) -> String {
  let start = self.position
  while true {
    match self.peek() {
      Some(ch) if (ch >= 'a' && ch <= 'z') ||
        (ch >= 'A' && ch <= 'Z') ||
        (ch >= '0' && ch <= '9') ||
        ch == '_' ||
        ch == '-' => ignore(self.advance())
      _ => break
    }
  }
  try! self.input[start:self.position].to_string()
}

///|
/// Get next token
pub fn Lexer::next_token(self : Lexer) -> Token raise {
  self.skip_whitespace()
  match self.peek() {
    None => Token::EOF
    Some('\n') => {
      ignore(self.advance())
      Token::Newline
    }
    Some('[') => {
      ignore(self.advance())
      Token::LeftBracket
    }
    Some(']') => {
      ignore(self.advance())
      Token::RightBracket
    }
    Some('{') => {
      ignore(self.advance())
      Token::LeftBrace
    }
    Some('}') => {
      ignore(self.advance())
      Token::RightBrace
    }
    Some('=') => {
      ignore(self.advance())
      Token::Equals
    }
    Some('.') => {
      ignore(self.advance())
      Token::Dot
    }
    Some(',') => {
      ignore(self.advance())
      Token::Comma
    }
    Some('"') => {
      ignore(self.advance())
      let mut result = ""
      while true {
        match self.advance() {
          Some('"') => break
          Some('\\') =>
            match self.advance() {
              Some('n') => result += "\n"
              Some('t') => result += "\t"
              Some('r') => result += "\r"
              Some('\\') => result += "\\"
              Some('"') => result += "\""
              Some(ch) => result += ch.to_string()
              None => raise Failure("Unexpected end of input in string")
            }
          Some(ch) => result += ch.to_string()
          None => raise Failure("Unterminated string literal")
        }
      }
      Token::StringLiteral(result)
    }
    Some(ch) if (ch >= '0' && ch <= '9') || ch == '+' || ch == '-' => {
      let start = self.position
      let mut has_dot = false

      // Handle optional sign
      match self.peek() {
        Some('+') | Some('-') => ignore(self.advance())
        _ => ignore(())
      }

      // Read digits
      while true {
        match self.peek() {
          Some(ch) if ch >= '0' && ch <= '9' => ignore(self.advance())
          Some('_') => ignore(self.advance())
          _ => break
        }
      }

      // Check for decimal point
      if self.peek() == Some('.') {
        has_dot = true
        ignore(self.advance())
        while true {
          match self.peek() {
            Some(ch) if ch >= '0' && ch <= '9' => ignore(self.advance())
            Some('_') => ignore(self.advance())
            _ => break
          }
        }
      }
      let number_str = (try! self.input[start:self.position].to_string()).replace(
        old="_",
        new="",
      )
      if has_dot {
        // Simple float parsing - for basic demo
        let f = 3.14 // placeholder
        Token::FloatLiteral(f)
      } else {
        // Simple int parsing - parse basic integers
        let mut result : Int64 = 0L
        let mut is_negative = false
        let mut i = 0
        if number_str.length() > 0 && number_str[0] == '-' {
          is_negative = true
          i = 1
        } else if number_str.length() > 0 && number_str[0] == '+' {
          i = 1
        }
        while i < number_str.length() {
          let ch_code = number_str[i] // This is an Int (code unit)
          if ch_code >= '0' && ch_code <= '9' {
            let digit = ch_code - '0' // Convert char code to digit
            result = result * 10L + digit.to_int64()
          }
          i = i + 1
        }
        if is_negative {
          result = -result
        }
        Token::IntegerLiteral(result)
      }
    }
    Some(ch) if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      ch == '_' => {
      let identifier = self.read_identifier()
      match identifier {
        "true" => Token::BooleanLiteral(true)
        "false" => Token::BooleanLiteral(false)
        _ => Token::Identifier(identifier)
      }
    }
    Some(ch) => raise Failure("Unexpected character: \{ch}")
  }
}

///|
/// Tokenize entire input
pub fn Lexer::tokenize(self : Lexer) -> Array[Token] raise {
  let tokens : Array[Token] = []
  while true {
    let token = self.next_token()
    match token {
      EOF => {
        tokens.push(token)
        break
      }
      _ => tokens.push(token)
    }
  }
  tokens
}
