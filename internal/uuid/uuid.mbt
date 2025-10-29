// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
#valtype
struct Uuid {
  hi : UInt64
  lo : UInt64
} derive(Eq, Compare, Hash)

///|
pub impl ToJson for Uuid with to_json(self : Uuid) -> Json {
  self.to_string().to_json()
}

///|
pub impl @json.FromJson for Uuid with from_json(json, json_path) -> Uuid raise {
  guard json is String(string) else {
    raise @json.JsonDecodeError((json_path, "Uuid::from_json: expected string"))
  }
  parse(string) catch {
    error =>
      raise @json.JsonDecodeError((json_path, "Uuid::from_json: \{error}"))
  }
}

///|
struct Generator(&Source)

///|
pub(open) trait Source {
  uint64(self : Self) -> UInt64 raise
}

///|
pub fn Generator::v4(self : Generator) -> Uuid raise {
  let hi = self.0.uint64()
  let lo = self.0.uint64()
  let hi = (hi & 0xFFFF_FFFF_FFFF_0FFF_UL) | 0x0000_0000_0000_4000_UL
  let lo = (lo & 0x0FFF_FFFF_FFFF_FFFF_UL) | 0x8000_0000_0000_0000_UL
  { hi, lo }
}

///|
pub impl Source for @random.Rand with uint64(self : @random.Rand) -> UInt64 raise {
  self.uint64()
}

///|
pub fn[Source : Source] generator(source : Source) -> Generator {
  Generator(source)
}

///|
pub let nil : Uuid = { hi: 0UL, lo: 0UL }

///|
pub let max : Uuid = {
  hi: 0xFFFF_FFFF_FFFF_FFFF_UL,
  lo: 0xFFFF_FFFF_FFFF_FFFF_UL,
}

///|
#as_free_fn
pub fn Uuid::of_bytes(bytes : Bytes) -> Uuid {
  let hi = (bytes[0].to_uint64() << 56) |
    (bytes[1].to_uint64() << 48) |
    (bytes[2].to_uint64() << 40) |
    (bytes[3].to_uint64() << 32) |
    (bytes[4].to_uint64() << 24) |
    (bytes[5].to_uint64() << 16) |
    (bytes[6].to_uint64() << 8) |
    bytes[7].to_uint64()
  let lo = (bytes[8].to_uint64() << 56) |
    (bytes[9].to_uint64() << 48) |
    (bytes[10].to_uint64() << 40) |
    (bytes[11].to_uint64() << 32) |
    (bytes[12].to_uint64() << 24) |
    (bytes[13].to_uint64() << 16) |
    (bytes[14].to_uint64() << 8) |
    bytes[15].to_uint64()
  { hi, lo }
}

///|
pub fn Uuid::to_bytes(self : Uuid) -> Bytes {
  let b : FixedArray[Byte] = FixedArray::make(16, 0)
  b[0] = (self.hi >> 56).to_byte()
  b[1] = (self.hi >> 48).to_byte()
  b[2] = (self.hi >> 40).to_byte()
  b[3] = (self.hi >> 32).to_byte()
  b[4] = (self.hi >> 24).to_byte()
  b[5] = (self.hi >> 16).to_byte()
  b[6] = (self.hi >> 8).to_byte()
  b[7] = self.hi.to_byte()
  b[8] = (self.lo >> 56).to_byte()
  b[9] = (self.lo >> 48).to_byte()
  b[10] = (self.lo >> 40).to_byte()
  b[11] = (self.lo >> 32).to_byte()
  b[12] = (self.lo >> 24).to_byte()
  b[13] = (self.lo >> 16).to_byte()
  b[14] = (self.lo >> 8).to_byte()
  b[15] = self.lo.to_byte()
  b.unsafe_reinterpret_as_bytes()
}

///|
suberror ParseError {
  UnexpectedEnd
  InvalidOctet(StringView)
  MissingDash(StringView)
  ExtraContent(StringView)
} derive(Show, ToJson)

///|
pub fn parse(hex : StringView) -> Uuid raise ParseError {
  let mut view = hex.view()
  fn parse_hex_octet(count : Int, value : UInt64) -> UInt64 raise ParseError {
    let mut value = value
    for _ in 0..<(count * 2) {
      match view {
        ['0'..='9' as c, .. rest] => {
          value = (value << 4) | (c.to_uint() - '0'.to_uint()).to_uint64()
          view = rest
        }
        ['a'..='f' as c, .. rest] => {
          value = (value << 4) | (c.to_uint() - 'a'.to_uint() + 10).to_uint64()
          view = rest
        }
        ['A'..='F' as c, .. rest] => {
          value = (value << 4) | (c.to_uint() - 'A'.to_uint() + 10).to_uint64()
          view = rest
        }
        [_, ..] => raise InvalidOctet(view)
        [] => raise UnexpectedEnd
      }
    }
    value
  }

  fn parse_dash() -> Unit raise ParseError {
    match view {
      ['-', .. rest] => view = rest
      _ => raise MissingDash(view)
    }
  }

  let hi = parse_hex_octet(4, 0UL)
  parse_dash()
  let hi = parse_hex_octet(2, hi)
  parse_dash()
  let hi = parse_hex_octet(2, hi)
  parse_dash()
  let lo = parse_hex_octet(2, 0UL)
  parse_dash()
  let lo = parse_hex_octet(6, lo)
  guard view.is_empty() else { raise ExtraContent(view) }
  { hi, lo }
}

///|
// let hex_table : ReadOnlyArray[Char] = [
//   '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
// ]
let hex_table : Bytes = b"0123456789abcdef"

///|
pub fn Uuid::to_string(self : Uuid) -> String {
  let builder = StringBuilder::new(size_hint=36)
  let mut hi = self.hi
  for _ in 0..<8 {
    builder.write_char(hex_table[(hi >> 60).to_int()].to_char())
    hi = hi << 4
  }
  builder.write_char('-')
  for _ in 0..<4 {
    builder.write_char(hex_table[(hi >> 60).to_int()].to_char())
    hi = hi << 4
  }
  builder.write_char('-')
  for _ in 0..<4 {
    builder.write_char(hex_table[(hi >> 60).to_int()].to_char())
    hi = hi << 4
  }
  builder.write_char('-')
  let mut lo = self.lo
  for _ in 0..<4 {
    builder.write_char(hex_table[(lo >> 60).to_int()].to_char())
    lo = lo << 4
  }
  builder.write_char('-')
  for _ in 0..<12 {
    builder.write_char(hex_table[(lo >> 60).to_int()].to_char())
    lo = lo << 4
  }
  builder.to_string()
}

///|
test {
  inspect(b'a'.to_char(), content="a")
}

///|
pub impl Show for Uuid with output(self : Uuid, logger : &Logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
pub enum Variant {
  ReservedNCS
  RFC9562(Version)
  ReservedMicrosoft
  ReservedFuture
} derive(Show, ToJson)

///|
pub(all) enum Version {
  V0 = 0
  V1 = 1
  V2 = 2
  V3 = 3
  V4 = 4
  V5 = 5
  V6 = 6
  V7 = 7
  V8 = 8
  V9 = 9
  V10 = 10
  V11 = 11
  V12 = 12
  V13 = 13
  V14 = 14
  V15 = 15
} derive(Show, ToJson)

///|
fn Version::from_uint64_unchecked(value : UInt64) -> Version = "%identity"

///|
pub fn Uuid::variant(self : Uuid) -> Variant {
  if (self.lo & (0x8000UL << 48)) == 0UL {
    ReservedNCS
  } else if (self.lo & (0x4000UL << 48)) == 0UL {
    RFC9562(Version::from_uint64_unchecked((self.hi >> 12) & 0xFUL))
  } else if (self.lo & (0x2000UL << 48)) == 0UL {
    ReservedMicrosoft
  } else {
    ReservedFuture
  }
}

///|
pub fn Uuid::version(self : Uuid) -> Version? {
  match self.variant() {
    RFC9562(ver) => Some(ver)
    _ => None
  }
}
