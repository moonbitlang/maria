///|
pub const Escape : Byte = '\x1b'

///|
pub const ClearToLineBeginning : Bytes = "\x1b[1K"

///|
pub const ClearToLineEnd : Bytes = "\x1b[0K"

///|
pub const ClearLine : Bytes = "\x1b[2K"

///|
pub const ClearScreenDown : Bytes = "\x1b[0J"

///|
pub fn csi(command : Bytes) -> Bytes {
  let buffer = @buffer.new()
  buffer.write_byte(Escape)
  buffer.write_byte('[')
  buffer.write_bytes(command)
  buffer.to_bytes()
}
