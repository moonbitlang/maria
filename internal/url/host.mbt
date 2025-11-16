///|
pub enum Host {
  Domain(String)
  IPv4(IPv4)
  IPv6(IPv6)
  Opaque(String)
} derive(ToJson)

///|
suberror ValidationError {
  DomainToAscii
  HostInvalidCodePoint
  IPv4EmptyPart
  IPv4TooManyParts
  IPv4NonNumericPart
  IPv4OutOfRangePart
  IPv6InvalidCompression
  IPv6MultipleCompression
  IPv6TooManyPieces
  IPv6InvalidCodePoint
  IPv6TooFewPieces
  IPv6Unclosed
  IPv4InIPv6InvalidCodePoint
  IPv4InIPv6TooManyPieces
  IPv4InIPv6OutOfRangePart
  IPv4InIPv6TooFewParts
  InvalidUrlUnit
  MissingSchemeNonRelativeUrl
  SpecialSchemeMissingFollowingSolidus
  InvalidReverseSolidus
  InvalidCredentials
  HostMissing
} derive(ToJson)

///|
fn percent_decode_string(input : StringView) -> Bytes {
  let bytes = @encoding/utf8.encode(input, bom=false)
  return percent_decode_bytes(bytes)
}

///|
fn percent_decode_bytes(input : Bytes) -> Bytes {
  let output = @buffer.new()
  loop input[:] {
    ['%', c0, c1, .. rest] as view => {
      let b0 = match c0 {
        '0'..='9' => c0.to_int() - '0'.to_int()
        'a'..='f' => c0.to_int() - 'a'.to_int() + 10
        'A'..='F' => c0.to_int() - 'A'.to_int() + 10
        _ => {
          output.write_byte('%')
          continue view[1:]
        }
      }
      let b1 = match c1 {
        '0'..='9' => c1.to_int() - '0'.to_int()
        'a'..='f' => c1.to_int() - 'a'.to_int() + 10
        'A'..='F' => c1.to_int() - 'A'.to_int() + 10
        _ => {
          output.write_byte('%')
          output.write_byte(c0)
          continue view[2:]
        }
      }
      output.write_byte(((b0 << 4) | b1).to_byte())
      continue rest
    }
    [byte, .. rest] => {
      output.write_byte(byte)
      continue rest
    }
    [] => break
  }
  output.contents()
}

///|
pub fn Host::parse(
  input : StringView,
  is_opaque? : Bool = false,
) -> Host raise ValidationError {
  match input {
    ['[', .. rest, ']'] => {
      let ipv6 = IPv6::parse(rest)
      IPv6(ipv6)
    }
    ['[', ..] => raise IPv6Unclosed
    input => {
      if is_opaque {
        let opaque_host = Host::parse_opaque(input)
        return Host::Opaque(opaque_host)
      }
      let domain = @encoding/utf8.decode_lossy(percent_decode_string(input))
      for c in domain {
        guard c.is_ascii() else { raise DomainToAscii }
      }
      let ascii_domain = domain.to_lower()
      if ends_in_a_number(ascii_domain) {
        return IPv4(IPv4::parse(ascii_domain))
      }
      return Domain(ascii_domain)
    }
  }
}

///|
fn ends_in_a_number(input : StringView) -> Bool {
  let parts = input.split(".").collect()
  match parts {
    [] | [""] => return false
    [.., last, ""] | [.., last] => {
      if last is "" {
        return false
      }
      match last {
        ['0', 'x' | 'X', .. last] =>
          for c in last {
            if c is ('0'..='9' | 'a'..='f' | 'A'..='F') {
              continue
            } else {
              return false
            }
          } else {
            return true
          }
        ['0'..='9', .. last] =>
          for c in last {
            if c is ('0'..='9') {
              continue
            } else {
              return false
            }
          } else {
            return true
          }
        _ => return false
      }
    }
  }
}

///|
test "ends_in_a_number" {
  @json.inspect(ends_in_a_number("example.com.123"), content=true)
  @json.inspect(!ends_in_a_number("example.com.abc"), content=true)
  @json.inspect(!ends_in_a_number("example.com."), content=true)
  @json.inspect(!ends_in_a_number("example.com"), content=true)
  @json.inspect(ends_in_a_number("example.0x1A"), content=true)
  @json.inspect(!ends_in_a_number("example.0xG1"), content=true)
  @json.inspect(!ends_in_a_number("example.09"), content=false)
  @json.inspect(ends_in_a_number("0xffffffff"), content=true)
}

///|
fn Host::parse_opaque(input : StringView) -> String raise ValidationError {
  loop input {
    [
      '\u{0000}'
      | '\u{0009}'
      | '\u{000a}'
      | '\u{000d}'
      | ' '
      | '#'
      | '/'
      | ':'
      | '<'
      | '>'
      | '?'
      | '@'
      | '['
      | '\\'
      | ']'
      | '^'
      | '|',
      ..,
    ] => raise HostInvalidCodePoint
    [
      '0'..='9'
      | 'a'..='z'
      | 'A'..='Z'
      | '!'
      | '$'
      | '&'
      | '\''
      | '('
      | ')'
      | '*'
      | '+'
      | ','
      | '-'
      | '.'
      | ';'
      | '='
      | '_'
      | '~'
      | '\u{00a0}'..='\u{10ffff}',
      .. rest,
    ] => continue rest
    [
      '%',
      '0'..='9'
      | 'a'..='f'
      | 'A'..='F',
      '0'..='9'
      | 'a'..='f'
      | 'A'..='F',
      .. rest,
    ] => continue rest
    _ => raise InvalidUrlUnit
  }
  utf8_percent_encode(input, c0_control_percent_encode_set)
}

///|
let hex_digits : ReadOnlyArray[Char] = [
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
]

///|
fn c0_control_percent_encode_set(char : Char) -> Bool {
  return char is ('\u{0000}'..='\u{001f}' | '\u{007f}'..<_)
}

///|
fn query_percent_encode_set(char : Char) -> Bool {
  return char
    is ('\u{0000}'..='\u{001f}' | '\u{007f}'..<_ | ' ' | '"' | '#' | '<' | '>')
}

///|
fn path_percent_encode_set(char : Char) -> Bool {
  return char
    is ('\u{0000}'..='\u{001f}'
    | '\u{007f}'..<_
    | ' '
    | '"'
    | '#'
    | '<'
    | '>'
    | '?'
    | '^'
    | '`'
    | '{'
    | '}')
}

///|
fn userinfo_percent_encode_set(char : Char) -> Bool {
  return char
    is ('\u{0000}'..='\u{001f}'
    | '\u{007f}'..<_
    | ' '
    | '"'
    | '#'
    | '<'
    | '>'
    | '?'
    | '^'
    | '`'
    | '{'
    | '}'
    | '/'
    | ':'
    | ';'
    | '='
    | '@'
    | '['..=']'
    | '|')
}

///|
#locals(percent_encode_set)
fn utf8_percent_encode(
  input : StringView,
  percent_encode_set : (Char) -> Bool,
  space_as_plus? : Bool = false,
) -> String {
  let output = StringBuilder::new()
  let encode_output = @encoding/utf8.encode(input)
  for byte in encode_output {
    if space_as_plus && byte is ' ' {
      output.write_char('+')
      continue
    }
    let isomorph = byte.to_char()
    if percent_encode_set(isomorph) {
      output.write_char('%')
      let byte = byte.to_int()
      output.write_char(hex_digits[(byte >> 4) & 0x0f])
      output.write_char(hex_digits[byte & 0x0f])
      continue
    } else {
      output.write_char(isomorph)
    }
  }
  output.to_string()
}
