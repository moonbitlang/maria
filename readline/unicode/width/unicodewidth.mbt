// Copyright 2012-2025 The Rust Project Developers
// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0>. This file may not be
// copied, modified, or distributed except according to those terms.

///|
/// Returns the [UAX #11](https://www.unicode.org/reports/tr11/) based width of `c`, or
/// `None` if `c` is a control character.
///
/// @param c The character to check
/// @param cjk If true, ambiguous width characters are treated as wide (CJK context).
///            If false, they are treated as narrow. Defaults to true.
/// @return The width of the character, or None if it's a control character
pub fn char(c : Char, cjk? : Bool = false) -> Int? {
  (if cjk { char_width_cjk_impl } else { char_width_impl })(c)
}

///|
/// Returns the [UAX #11](https://www.unicode.org/reports/tr11/) based width of a string.
///
/// @param s The string to measure
/// @param cjk If true, ambiguous width characters are treated as wide (CJK context).
///            If false, they are treated as narrow. Defaults to true.
/// @return The total width of the string
pub fn string(s : StringView, cjk? : Bool = false) -> Int {
  (if cjk { str_width_cjk_impl } else { str_width_impl })(s)
}
