///|
#borrow(prompt)
extern "c" fn c_readline(prompt : Bytes) -> @c.Pointer[Byte] = "moonbit_maria_readline"

///|
pub fn readline(prompt : @string.View) -> String? raise {
  let prompt = @encoding.encode(prompt, encoding=UTF8)
  let s = c_readline(prompt)
  if s.is_null() {
    return None
  }
  let buffer = @buffer.new()
  for i = 0; s[i] != 0; i = i + 1 {
    buffer.write_byte(s[i])
  }
  @stdlib.free(s)
  return Some(@encoding.decode(buffer.to_bytes(), encoding=UTF8))
}
