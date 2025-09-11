///|
pub fn char_width_left(string : @bytes.View, index : Int) -> Int {
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
  guard @unicodewidth.char_width(char) is Some(width) else { return 1 }
  width
}

///|
pub fn char_size_left(string : @bytes.View, index : Int) -> Int {
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
    guard @unicodewidth.char_width(char) is Some(char_width) else {
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
pub fn char_width_right(string : @bytes.View, index : Int) -> Int {
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
  guard @unicodewidth.char_width(char) is Some(width) else { return 1 }
  width
}

///|
pub fn char_size_right(string : @bytes.View, index : Int) -> Int {
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
  guard @unicodewidth.char_width(char) is Some(width) else { return 1 }
  width
}
