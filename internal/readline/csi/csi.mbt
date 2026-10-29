///|
/// ASCII escape byte for ANSI control sequences.
pub const Escape : Byte = b'\x1b'

///|
/// Clear from cursor to the beginning of the line.
pub const ClearToLineBeginning : Bytes = b"\x1b[1K"

///|
/// Clear from cursor to the end of the line.
pub const ClearToLineEnd : Bytes = b"\x1b[0K"

///|
/// Clear the entire line.
pub const ClearLine : Bytes = b"\x1b[2K"

///|
/// Clear the screen from cursor downward.
pub const ClearScreenDown : Bytes = b"\x1b[0J"

///|
/// Build a CSI escape sequence from a command payload.
pub fn csi(command : Bytes) -> Bytes {
  let buffer = Buffer()
  buffer.write_byte(Escape)
  buffer.write_byte(b'[')
  buffer.write_bytes(command)
  buffer.to_bytes()
}
