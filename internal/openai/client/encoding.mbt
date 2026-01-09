///|
let hex_table : Bytes = b"0123456789ABCDEF"

///|
pub fn encode_query_component(value : String) -> String {
  let bytes = @encoding/utf8.encode(value)
  let builder = StringBuilder::new()
  for b in bytes {
    if is_unreserved(b) {
      builder.write_char(b.to_char())
    } else {
      builder.write_char('%')
      builder.write_char(hex_table[(b >> 4).to_int()].to_char())
      builder.write_char(hex_table[(b & 0x0f).to_int()].to_char())
    }
  }
  builder.to_string()
}

///|
fn is_unreserved(b : Byte) -> Bool {
  match b {
    b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => true
    _ => false
  }
}
