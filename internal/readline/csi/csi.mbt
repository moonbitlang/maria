///|
/// ASCII escape byte for ANSI control sequences.
pub const Escape : Byte = '\x1b'

///|
/// Clear from cursor to the beginning of the line.
pub const ClearToLineBeginning : Bytes = "\x1b[1K"

///|
/// Clear from cursor to the end of the line.
pub const ClearToLineEnd : Bytes = "\x1b[0K"

///|
/// Clear the entire line.
pub const ClearLine : Bytes = "\x1b[2K"

///|
/// Clear the screen from cursor downward.
pub const ClearScreenDown : Bytes = "\x1b[0J"

///|
/// Build a CSI escape sequence from a command payload.
pub fn csi(command : Bytes) -> Bytes {
  let buffer = @buffer.new()
  buffer.write_byte(Escape)
  buffer.write_byte('[')
  buffer.write_bytes(command)
  buffer.to_bytes()
}
