///|
/// Return the display width of the UTF-8 character immediately left of `index`.
/// `index` is a byte offset into `string`.
pub fn char_width_left(string : BytesView, index : Int) -> Int {
  let char = match string[:index] {
    [] => return 0
    [.., 0x00..=0x7F as b0] => Some(b0.to_char())
    [.., 0xC2..=0xDF as b0, 0x80..=0xBF as b1] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      (((b0 & 0x1F) << 6) | (b1 & 0x3F)).to_char()
    }
    [.., 0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2]
    | [.., 0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2]
    | [.., 0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2]
    | [.., 0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let b2 = b2.to_int()
      (((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)).to_char()
    }
    [.., 0xF0 as b0, 0x90..=0xBF as b1, 0x80..=0xBF as b2, 0x80..=0xBF as b3]
    | [
      ..,
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
    ]
    | [.., 0xF4 as b0, 0x80..=0x8F as b1, 0x80..=0xBF as b2, 0x80..=0xBF as b3] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let b2 = b2.to_int()
      let b3 = b3.to_int()
      (((b0 & 0x07) << 18) |
      ((b1 & 0x3F) << 12) |
      ((b2 & 0x3F) << 6) |
      (b3 & 0x3F)).to_char()
    }
    [..] => return 1
  }
  guard char is Some(char) else { return 1 }
  guard @unicode/width.char(char) is Some(width) else { return 1 }
  width
}

///|
/// Return the UTF-8 byte length to move left from `index`.
/// This includes any trailing zero-width marks before the base character.
pub fn char_size_left(string : BytesView, index : Int) -> Int {
  for width = 0, string = string[:index] {
    let mut char : Char? = None
    let mut size = 0
    let rest = match string {
      [] => return 0
      [.. rest, 0x00..=0x7F as b0] => {
        size = 1
        char = Some(b0.to_char())
        rest
      }
      [.. rest, 0xC2..=0xDF as b0, 0x80..=0xBF as b1] => {
        size = 2
        let b0 = b0.to_int()
        let b1 = b1.to_int()
        char = (((b0 & 0x1F) << 6) | (b1 & 0x3F)).to_char()
        rest
      }
      [.. rest, 0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2]
      | [.. rest, 0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2]
      | [.. rest, 0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2]
      | [.. rest, 0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2] => {
        size = 3
        let b0 = b0.to_int()
        let b1 = b1.to_int()
        let b2 = b2.to_int()
        char = (((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)).to_char()
        rest
      }
      [
        .. rest,
        0xF0 as b0,
        0x90..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
      ]
      | [
        .. rest,
        0xF1..=0xF3 as b0,
        0x80..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
      ]
      | [
        .. rest,
        0xF4 as b0,
        0x80..=0x8F as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
      ] => {
        size = 4
        let b0 = b0.to_int()
        let b1 = b1.to_int()
        let b2 = b2.to_int()
        let b3 = b3.to_int()
        char = (((b0 & 0x07) << 18) |
        ((b1 & 0x3F) << 12) |
        ((b2 & 0x3F) << 6) |
        (b3 & 0x3F)).to_char()
        rest
      }
      [..] => return width + 1
    }
    guard char is Some(char) else { return width + 1 }
    guard @unicode/width.char(char) is Some(char_width) else {
      return width + 1
    }
    if char_width == 0 {
      continue width + size, rest
    } else {
      return width + size
    }
  }
}

///|
/// Return the display width of the UTF-8 character at `index`.
/// `index` is a byte offset into `string`.
pub fn char_width_right(string : BytesView, index : Int) -> Int {
  let char : Char? = match string[index:] {
    [] => return 0
    [0x00..=0x7F as b0, ..] => Some(b0.to_char())
    [0xC2..=0xDF as b0, 0x80..=0xBF as b1, ..] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      (((b0 & 0x1F) << 6) | (b1 & 0x3F)).to_char()
    }
    [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, ..]
    | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, ..]
    | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, ..]
    | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, ..] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let b2 = b2.to_int()
      (((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)).to_char()
    }
    [0xF0 as b0, 0x90..=0xBF as b1, 0x80..=0xBF as b2, 0x80..=0xBF as b3, ..]
    | [
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      ..,
    ]
    | [0xF4 as b0, 0x80..=0x8F as b1, 0x80..=0xBF as b2, 0x80..=0xBF as b3, ..] => {
      let b0 = b0.to_int()
      let b1 = b1.to_int()
      let b2 = b2.to_int()
      let b3 = b3.to_int()
      (((b0 & 0x07) << 18) |
      ((b1 & 0x3F) << 12) |
      ((b2 & 0x3F) << 6) |
      (b3 & 0x3F)).to_char()
    }
    [..] => None
  }
  guard char is Some(char) else { return 1 }
  guard @unicode/width.char(char) is Some(width) else { return 1 }
  width
}

///|
/// Return the UTF-8 byte length to move right from `index`.
/// This includes any following zero-width marks after the base character.
pub fn char_size_right(string : BytesView, index : Int) -> Int {
  for total = 0, rest = string[index:], saw_nonzero = false {
    let mut char : Char? = None
    let mut size = 0
    let next = match rest {
      [] => return total
      [0x00..=0x7F as b0, .. tail] => {
        size = 1
        char = Some(b0.to_char())
        tail
      }
      [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. tail] => {
        size = 2
        let b0 = b0.to_int()
        let b1 = b1.to_int()
        char = (((b0 & 0x1F) << 6) | (b1 & 0x3F)).to_char()
        tail
      }
      [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. tail]
      | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. tail]
      | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. tail]
      | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. tail] => {
        size = 3
        let b0 = b0.to_int()
        let b1 = b1.to_int()
        let b2 = b2.to_int()
        char = (((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)).to_char()
        tail
      }
      [
        0xF0 as b0,
        0x90..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. tail,
      ]
      | [
        0xF1..=0xF3 as b0,
        0x80..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. tail,
      ]
      | [
        0xF4 as b0,
        0x80..=0x8F as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. tail,
      ] => {
        size = 4
        let b0 = b0.to_int()
        let b1 = b1.to_int()
        let b2 = b2.to_int()
        let b3 = b3.to_int()
        char = (((b0 & 0x07) << 18) |
        ((b1 & 0x3F) << 12) |
        ((b2 & 0x3F) << 6) |
        (b3 & 0x3F)).to_char()
        tail
      }
      [..] => return if total == 0 { 1 } else { total }
    }
    guard char is Some(char) else { return if total == 0 { 1 } else { total } }
    let width = @unicode/width.char(char).unwrap_or(1)
    if !saw_nonzero {
      let total = total + size
      if width == 0 {
        return total
      }
      continue total, next, true
    }
    if width == 0 {
      continue total + size, next, saw_nonzero
    }
    return total
  }
}
