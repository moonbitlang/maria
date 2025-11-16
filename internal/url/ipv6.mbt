///|
struct IPv6(FixedArray[UInt16])

///|
pub impl ToJson for IPv6 with to_json(self : IPv6) -> Json {
  self.0.to_json()
}

///|
pub fn IPv6::parse(input : StringView) -> IPv6 raise ValidationError {
  // 1. Let `address` be a new IPv6 address whose pieces are all 0.
  let address : FixedArray[UInt16] = FixedArray::make(8, 0)
  // 2. Let `piece_index` be `0`.
  let mut piece_index : Int = 0
  // 3. Let compress be `None`.
  let mut compress : Int? = None

  // 4. Let `pointer` be a pointer for `input`.
  //
  // Note: We do not have pointer arithmetic in Moonbit, so we will just
  //       manipulate the `input` directly in `match`/`loop` expressions below.

  // 5. If `c` is U+003A (:), then:
  let input = match input {
    [':', ':', .. remaining] => {
      // 5.3. Increase `piece_index` by 1 and then set compress to `piece_index`.
      piece_index = piece_index + 1
      compress = Some(piece_index)
      // 5.2. Increase `pointer` by 2.
      remaining
    }
    [':', ..] =>
      // 5.1. If `remaining` does not start with U+003A (:),
      //      IPv6-invalid-compression validation error, return failure.
      raise IPv6InvalidCompression
    input => input
  }

  // 6. While `c` is ...
  loop input {
    // ... not the EOF code point:
    [] => break
    // 6.1. If `piece_index` is 8, IPv6-too-many-pieces validation error,
    //      return failure.
    _ if piece_index == 8 => raise IPv6TooManyPieces
    // 6.2. If c is U+003A (:), then:
    [':', .. remaining] => {
      // 6.2.1. If `compress` is non-null, IPv6-multiple-compression validation
      //        error, return failure.
      if compress is Some(_) {
        raise IPv6MultipleCompression
      }
      // 6.2.2. increase pointer and `piece_index` by 1, set `compress` to
      //        `piece_index`, and then continue.
      piece_index = piece_index + 1
      compress = Some(piece_index)
      continue remaining
    }
    input => {
      // 6.3. Let `value` and `length` be 0.
      let mut value : UInt16 = 0
      let mut length = 0
      // 6.4. While `length` is less than 4 and c is an ASCII hex digit, set
      //      `value` to `value` × 0x10 + c interpreted as hexadecimal number,
      //      and increase pointer and `length` by 1.
      let remaining = for input = input; length < 4; {
        match input {
          ['0'..='9' as c, .. rest] => {
            value = value * 0x10 + (c.to_int().to_uint16() - '0')
            length = length + 1
            continue rest
          }
          ['a'..='f' as c, .. rest] => {
            value = value * 0x10 + (c.to_int().to_uint16() - 'a' + 10)
            length = length + 1
            continue rest
          }
          ['A'..='F' as c, .. rest] => {
            value = value * 0x10 + (c.to_int().to_uint16() - 'A' + 10)
            length = length + 1
            continue rest
          }
          _ => break input
        }
      } else {
        input
      }
      let remaining = match remaining {
        [] => remaining
        // 6.5. If c is U+002E (.), then:
        ['.', ..] => {
          // 6.5.1. If [length] is 0, IPv4-in-IPv6-invalid-code-point validation
          //        error, return failure.
          if length == 0 {
            raise IPv4InIPv6InvalidCodePoint
          }
          // 6.5.2. Decrease pointer by length.
          //
          // Note: We does not have pointer arithmetic, so this is achieved by
          //       using `input` instead of `remaining` directly in the loop
          //       below.

          // 6.5.3. If `piece_index` is greater than 6,
          //        IPv4-in-IPv6-too-many-pieces validation error, return
          //        failure.
          if piece_index > 6 {
            raise IPv4InIPv6TooManyPieces
          }

          // 6.5.4. Let `numbers_seen` be 0.
          let mut numbers_seen = 0
          // 6.5.5. While `c` is not ...
          loop input {
            // ... the EOF code point:
            [] => break
            // 6.5.5.1. Let `ipv4_piece` be `None`.
            //
            // Note: Here we use `UInt16` directly since we will always
            //       initialize it in the loop below, and there is no need to
            //       have it initialized here as an `UInt16?`.
            //
            // 6.5.5.2. If `numbers_seen` is greater than 0, then:
            //    1. If c is U+002E (.), increase pointer and `numbers_seen`
            //       is less than 4, then increase `pointer` by 1.
            //    2. Otherwise, IPv4-in-IPv6-invalid-code-point validation
            //       error, return failure.
            //
            // Note: Here we test if the `c` is `.` first even if `numbers_seen`
            //       is `0`. This is because in the immediately following
            //       branching we will be testing if `c` is a digit, and raise
            //       the same error (IPv4-in-IPv6-invalid-code-point) if not.
            //       Therefore, the code logic here is equivalent to what is
            //       described in the spec.
            ['.', .. remaining] =>
              if numbers_seen is (1..<4) {
                continue remaining
              } else {
                raise IPv4InIPv6InvalidCodePoint
              }
            // 6.5.5.4. While `c` is an ASCII digit:
            ['0'..='9' as c, .. remaining] => {
              let mut ipv4_piece : UInt16 = c.to_int().to_uint16() - '0'
              // 6.5.5.4. While `c` is an ASCII digit:
              let remaining = loop remaining {
                ['0'..='9' as c, .. remaining] => {
                  // 6.5.5.4.1. Let `number` be `c` interpreted as decimal number.
                  let number = c.to_int().to_uint16() - '0'
                  // 6.5.5.4.2. If `ipv4_piece` is `None`, then set `ipv4_piece`
                  // │  to `number`.
                  // │
                  // │  Note: This is actually done above before entering
                  // │  this loop.
                  // │  Otherwise, if `ipv4_piece` is 0, IPv4-in-IPv6-invalid-code-point
                  // │  validation error, return failure.
                  if ipv4_piece is 0 {
                    raise IPv4InIPv6InvalidCodePoint
                  }
                  // │  Otherwise, set `ipv4_piece` to `ipv4_piece` × 10 + `number`.
                  ipv4_piece = ipv4_piece * 10 + number
                  // 6.5.5.4.3. If `ipv4_piece` is greater than 255, IPv4-in-IPv6-out-of-range-part
                  //    validation error, return failure.
                  if ipv4_piece > 255 {
                    raise IPv4InIPv6OutOfRangePart
                  }
                  // 6.5.5.4.4. Increase `pointer` by 1.
                  continue remaining
                }
                remaining => break remaining
              }
              // 6.5.5.5. Set `address[piece_index]` to
              //          `address[piece_index]` × 0x100 + `ipv4_piece`.
              address[piece_index] = address[piece_index] * 0x100 + ipv4_piece
              // 6.5.5.6. Increase `numbers_seen` by 1.
              numbers_seen = numbers_seen + 1
              // 6.5.5.7. If `numbers_seen` is 2 or 4, increase `piece_index`
              //          by 1.
              if numbers_seen is (2 | 4) {
                piece_index = piece_index + 1
              }
              continue remaining
            }
            // 6.5.5.3. If `c` is not an ASCII digit, IPv4-in-IPv6-invalid-code-point
            //          validation error, return failure.
            [_, ..] => raise IPv4InIPv6InvalidCodePoint
          }
          // 6.5.6. If `numbers_seen` is not 4, IPv4-in-IPv6-too-few-parts validation
          //        error, return failure.
          if numbers_seen != 4 {
            raise IPv4InIPv6TooFewParts
          }
          // 6.5.7. Break.
          break
        }
        // 6.6. Otherwise, if `c` is U+003A (:):
        // 6.6.2. If `c` is the EOF code point, IPv6-invalid-code-point validation error,
        //       return failure.
        [':'] => raise IPv6InvalidCodePoint
        // 6.6.1. Increase `pointer` by 1.
        [':', .. remaining] => remaining
        // 6.7. Otherwise, if `c` is not the EOF code point, IPv6-invalid-code-point
        //       validation error, return failure.
        [_, ..] => raise IPv6InvalidCodePoint
      }
      // 6.8. Set `address[piece_index]` to `value`.
      address[piece_index] = value
      // 6.9. Increase `piece_index` by 1.
      piece_index = piece_index + 1
      continue remaining
    }
  }
  if compress is Some(compress) {
    // 7. If `compress` is non-null, then:

    // 7.1. Let `swaps` be `piece_index` - `compress`.
    let mut swaps = piece_index - compress
    // 7.2. Let `piece_index` be `7`.
    piece_index = 7
    // 7.3. While `swaps` is greater than `0`, swap `address[piece_index]` and
    //      `address[compress + swaps - 1]`, decrease `piece_index` by `1`, and
    //      decrease `swaps` by `1`.
    while piece_index != 0 && swaps > 0 {
      address.swap(piece_index, compress + swaps - 1)
      piece_index = piece_index - 1
      swaps = swaps - 1
    }
  } else if piece_index != 8 {
    // 8. Otherwise, if `compress` is null and `piece_index` is not `8`,
    //    IPv6-too-few-pieces validation error, return failure.
    raise IPv6TooFewPieces
  }
  // 9. Return address.
  IPv6(address)
}
