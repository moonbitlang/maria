// Copyright 2012-2025 The Rust Project Developers
// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0>. This file may not be
// copied, modified, or distributed except according to those terms.

///|
#callsite(autofill(loc))
fn assert_str_width(
  s : String,
  nocjk : Int,
  cjk : Int,
  loc~ : SourceLoc,
) -> Unit raise {
  assert_eq(
    (@width.string(s, cjk=false), @width.string(s, cjk=true)),
    (nocjk, cjk),
    loc~,
  )
}

///|
#callsite(autofill(loc))
fn assert_char_width(
  c : Char,
  nocjk : Int?,
  cjk : Int?,
  loc~ : SourceLoc,
) -> Unit raise {
  assert_eq(
    (@width.char(c, cjk=false), @width.char(c, cjk=true)),
    (nocjk, cjk),
    loc~,
  )
}

///|
test "test_str" {
  assert_str_width("ｈｅｌｌｏ", 10, 10)
  assert_str_width("\u{0}\u{0}\u{0}\u{1}\u{1}", 5, 5)
  assert_str_width("", 0, 0)
  assert_str_width("\u{2081}\u{2082}\u{2083}\u{2084}", 4, 8)
}

///|
test "test_emoji" {
  assert_str_width("👩", 2, 2) // Woman
  assert_str_width("🔬", 2, 2) // Microscope
  assert_str_width("👩‍🔬", 2, 2) // Woman scientist
}

///|
test "test_bad_devanagari" {
  assert_str_width("क", 1, 1) // Devanagari letter Ka
  assert_str_width("ष", 1, 1) // Devanagari letter Ssa
  assert_str_width("क्ष", 2, 2) // Ka + Virama + Ssa
}

///|
test "test_char" {
  assert_char_width('ｈ', Some(2), Some(2))
  assert_char_width('\u{0}', None, None)
  assert_char_width('\u{1}', None, None)
  assert_char_width('\u{2081}', Some(1), Some(2))
}

///|
test "test_char2" {
  assert_char_width('\u{A}', None, None)
  assert_char_width('w', Some(1), Some(1))
  assert_char_width('ｈ', Some(2), Some(2))
  assert_char_width('\u{AD}', Some(0), Some(0))
  assert_char_width('\u{1160}', Some(0), Some(0))
  assert_char_width('\u{A1}', Some(1), Some(2))
  assert_char_width('\u{300}', Some(0), Some(0))
}

///|
test "unicode_12" {
  assert_char_width('\u{1F971}', Some(2), Some(2))
}

///|
test "test_default_ignorable" {
  assert_char_width('\u{1160}', Some(0), Some(0))
  assert_char_width('\u{3164}', Some(0), Some(0))
  assert_char_width('\u{FFA0}', Some(0), Some(0))
  assert_char_width('\u{E0000}', Some(0), Some(0))
}

///|
test "test_ambiguous" {
  assert_str_width("\u{B7}", 1, 2)
  assert_str_width("\u{387}", 1, 2)
  assert_str_width("\u{A8}", 1, 1)
  assert_str_width("\u{2C9}", 1, 1)
}

///|
test "test_jamo" {
  assert_char_width('\u{1100}', Some(2), Some(2))
  assert_char_width('\u{A97C}', Some(2), Some(2))
  // Special case: U+115F HANGUL CHOSEONG FILLER
  assert_char_width('\u{115F}', Some(2), Some(2))
  assert_char_width('\u{1160}', Some(0), Some(0))
  assert_char_width('\u{D7C6}', Some(0), Some(0))
  assert_char_width('\u{11A8}', Some(0), Some(0))
  assert_char_width('\u{D7FB}', Some(0), Some(0))
}

///|
test "test_prepended_concatenation_marks" {
  let test_chars_width_1 = [
    '\u{600}', '\u{601}', '\u{602}', '\u{603}', '\u{604}', '\u{6DD}', '\u{110BD}',
    '\u{110CD}',
  ]
  for c in test_chars_width_1 {
    assert_char_width(c, Some(1), Some(1))
  }
  let test_chars_width_0 = [
    '\u{605}', '\u{70F}', '\u{890}', '\u{891}', '\u{8E2}',
  ]
  for c in test_chars_width_0 {
    assert_char_width(c, Some(0), Some(0))
  }
}

///|
test "test_gcb_prepend" {
  assert_str_width("ൎഉ", 1, 1)
  assert_str_width("\u{11A89}", 0, 0)
}

///|
test "test_interlinear_annotation_chars" {
  assert_char_width('\u{FFF9}', Some(1), Some(1))
  assert_char_width('\u{FFFA}', Some(1), Some(1))
  assert_char_width('\u{FFFB}', Some(1), Some(1))
}

///|
test "test_hieroglyph_format_controls" {
  assert_char_width('\u{13430}', Some(1), Some(1))
  assert_char_width('\u{13436}', Some(1), Some(1))
  assert_char_width('\u{1343C}', Some(1), Some(1))
}

///|
test "test_marks" {
  // Nonspacing marks have 0 width
  assert_char_width('\u{301}', Some(0), Some(0))
  // Enclosing marks have 0 width
  assert_char_width('\u{20DD}', Some(0), Some(0))
  // Some spacing marks have width 1
  assert_char_width('\u{9CB}', Some(1), Some(1))
  // But others have width 0
  assert_char_width('\u{9BE}', Some(0), Some(0))
}

///|
test "test_devanagari_caret" {
  assert_char_width('\u{A8FA}', Some(0), Some(0))
}

///|
test "test_solidus_overlay" {
  assert_str_width("<\u{338}", 1, 2)
  assert_str_width("=\u{338}", 1, 2)
  assert_str_width(">\u{338}", 1, 2)
  assert_str_width("=\u{301}\u{338}", 1, 2)
  assert_str_width("=\u{338}\u{301}", 1, 2)
  assert_str_width("=\u{FE0F}\u{338}", 1, 2)
  assert_str_width("#\u{FE0F}\u{338}", 2, 2)
  assert_str_width("#\u{338}\u{FE0F}", 1, 1)
  assert_str_width("\u{6B8}\u{338}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{338}\u{FE0E}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{338}\u{FE0F}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{FE0E}\u{338}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{FE0F}\u{338}\u{627}", 1, 1)
  assert_str_width("=\u{338}\u{627}", 2, 3)
}

///|
test "test_emoji_presentation" {
  assert_char_width('\u{23}', Some(1), Some(1))
  assert_char_width('\u{FE0F}', Some(0), Some(0))
  assert_str_width("\u{23}\u{FE0F}", 2, 2)
  assert_str_width("a\u{23}\u{FE0F}a", 4, 4)
  assert_str_width("\u{23}a\u{FE0F}", 2, 2)
  assert_str_width("a\u{FE0F}", 1, 1)
  assert_str_width("\u{23}\u{23}\u{FE0F}a", 4, 4)
  assert_str_width("\u{2A}\u{FE0F}", 2, 2)
  assert_str_width("\u{23F9}\u{FE0F}", 2, 2)
  assert_str_width("\u{24C2}\u{FE0F}", 2, 2)
  assert_str_width("\u{1F6F3}\u{FE0F}", 2, 2)
  assert_str_width("\u{1F700}\u{FE0F}", 1, 1)
  assert_str_width("\u{2A}\u{301}\u{FE0F}", 1, 1)
  assert_str_width("\u{2A}\u{200D}\u{FE0F}", 1, 1)
  assert_str_width("\u{2A}\u{FE0E}\u{FE0F}", 1, 1)
}

///|
test "test_text_presentation" {
  assert_char_width('\u{FE0E}', Some(0), Some(0))
  assert_char_width('\u{2648}', Some(2), Some(2))
  assert_str_width("\u{2648}\u{FE0E}", 1, 2)
  assert_str_width("\u{2648}\u{FE0E}\u{FE0F}", 1, 2)
  assert_str_width("\u{2648}\u{FE0F}\u{FE0E}", 2, 2)
  assert_str_width("\u{1F21A}\u{FE0E}", 2, 2)
  assert_str_width("\u{301}\u{FE0E}", 0, 0)
  assert_str_width("a\u{FE0E}", 1, 1)
  assert_str_width("𘀀\u{FE0E}", 2, 2)
  assert_str_width("\u{2648}\u{301}\u{FE0E}", 2, 2)
  assert_str_width("\u{2648}\u{200D}\u{FE0E}", 2, 2)
}

///|
test "test_control_line_break" {
  assert_char_width('\u{2028}', Some(1), Some(1))
  assert_char_width('\u{2029}', Some(1), Some(1))
  assert_char_width('\r', None, None)
  assert_char_width('\n', None, None)
  assert_str_width("\r", 1, 1)
  assert_str_width("\n", 1, 1)
  assert_str_width("\r\n", 1, 1)
  assert_str_width("\u{0}", 1, 1)
  assert_str_width("1\t2\r\n3\u{85}4", 7, 7)
  assert_str_width("\r\u{FE0F}\n", 2, 2)
  assert_str_width("\r\u{200D}\n", 2, 2)
}

///|
test "char_str_consistent" {
  for i in 0..=0x10FFFF {
    let c = i.unsafe_to_char()
    assert_eq(
      @width.char(c, cjk=false).unwrap_or(1),
      @width.string(c.to_string(), cjk=false),
    )
    assert_eq(
      @width.char(c, cjk=true).unwrap_or(1),
      @width.string(c.to_string(), cjk=true),
    )
  }
}

///|
test "test_lisu_tones" {
  let test_chars = [
    '\u{A4F8}', '\u{A4F9}', '\u{A4FA}', '\u{A4FB}', '\u{A4FC}', '\u{A4FD}',
  ]
  for c in test_chars {
    assert_char_width(c, Some(1), Some(1))
    assert_str_width(c.to_string(), 1, 1)
  }
  for c1 in 0xA4F8..=0xA4FB {
    for c2 in 0xA4FC..=0xA4FD {
      let s = c1.unsafe_to_char().to_string() + c2.unsafe_to_char().to_string()
      match (c1, c2) {
        ('\u{A4F8}'..='\u{A4FB}', '\u{A4FC}'..='\u{A4FD}') =>
          assert_str_width(s, 1, 1)
        _ => assert_str_width(s, 2, 2)
      }
    }
  }
  assert_str_width("ꓪꓹ", 2, 2)
  assert_str_width("ꓪꓹꓼ", 2, 2)
  assert_str_width("ꓪꓹ\u{FE0F}ꓼ", 2, 2)
  assert_str_width("ꓪꓹ\u{200D}ꓼ", 2, 2)
  assert_str_width("ꓪꓹꓼ\u{FE0F}", 2, 2)
  assert_str_width("ꓪꓹ\u{301}ꓼ", 3, 3)
  assert_str_width("ꓪꓹꓹ", 3, 3)
  assert_str_width("ꓪꓼꓼ", 3, 3)
}

///|
test "test_hebrew_alef_lamed" {
  assert_str_width("\u{5D0}", 1, 1)
  assert_str_width("\u{5DC}", 1, 1)
  assert_str_width("\u{5D0}\u{5DC}", 2, 2)
  assert_str_width("\u{5D0}\u{200D}\u{5DC}", 1, 1)
  assert_str_width(
    "\u{5D0}\u{200D}\u{200D}\u{200D}\u{200D}\u{200D}\u{200D}\u{200D}\u{5DC}", 1,
    1,
  )
  assert_str_width("\u{5D0}\u{5D0}\u{200D}\u{5DC}", 2, 2)
  assert_str_width(
    "\u{5D0}\u{5D0}\u{200D}\u{200D}\u{200D}\u{200D}\u{200D}\u{200D}\u{5DC}", 2, 2,
  )
  assert_str_width("\u{5D0}\u{FE0F}\u{200D}\u{FE0F}\u{5DC}\u{FE0F}", 1, 1)
  assert_str_width("\u{5D0}\u{FE0E}\u{200D}\u{FE0E}\u{5DC}\u{FE0E}", 1, 1)
}

///|
test "test_arabic_lam_alef" {
  assert_str_width("\u{644}", 1, 1)
  assert_str_width("\u{6B8}", 1, 1)
  assert_str_width("\u{623}", 1, 1)
  assert_str_width("\u{627}", 1, 1)
  assert_str_width("\u{644}\u{623}", 1, 1)
  assert_str_width("\u{644}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{623}", 1, 1)
  assert_str_width("\u{6B8}\u{627}", 1, 1)
  assert_str_width("\u{644}\u{65F}\u{65E}\u{623}", 1, 1)
  assert_str_width("\u{644}\u{65F}\u{65E}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{65F}\u{65E}\u{623}", 1, 1)
  assert_str_width("\u{6B8}\u{65F}\u{65E}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{FE0E}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{FE0F}\u{627}", 1, 1)
  assert_str_width("\u{6B8}\u{17B5}\u{627}", 1, 1)
  assert_str_width("\u{644}\u{644}\u{623}", 2, 2)
  assert_str_width("\u{644}\u{644}\u{627}", 2, 2)
  assert_str_width("\u{6B8}\u{6B8}\u{623}", 2, 2)
  assert_str_width("\u{6B8}\u{6B8}\u{627}", 2, 2)
  assert_str_width("\u{644}\u{200D}\u{623}", 2, 2)
  assert_str_width("\u{644}\u{200D}\u{627}", 2, 2)
  assert_str_width("\u{6B8}\u{200D}\u{623}", 2, 2)
  assert_str_width("\u{6B8}\u{200D}\u{627}", 2, 2)
  assert_str_width("\u{644}\u{1E94B}\u{623}", 3, 3)
  assert_str_width("\u{644}\u{1E94B}\u{627}", 3, 3)
  assert_str_width("\u{6B8}\u{1E94B}\u{623}", 3, 3)
  assert_str_width("\u{6B8}\u{1E94B}\u{627}", 3, 3)
}

///|
test "test_buginese_a_i_ya" {
  assert_str_width("\u{1A15}", 1, 1)
  assert_str_width("\u{1A17}", 0, 0)
  assert_str_width("\u{1A10}", 1, 1)
  assert_str_width("\u{1A15}\u{1A17}\u{200D}\u{1A10}", 1, 1)
  assert_str_width(
    "\u{1A15}\u{1A17}\u{200D}\u{200D}\u{200D}\u{200D}\u{1A10}", 1, 1,
  )
  assert_str_width("\u{1A15}\u{1A17}\u{200D}\u{338}", 1, 1)
  assert_str_width("\u{1A15}\u{FE0E}\u{1A17}\u{200D}", 1, 1)
  assert_str_width("\u{1A15}\u{FE0F}\u{1A17}\u{200D}", 1, 1)
  assert_str_width("\u{1A15}\u{1A17}\u{FE0E}\u{200D}", 1, 1)
  assert_str_width("\u{1A15}\u{1A17}\u{FE0F}\u{200D}", 1, 1)
  assert_str_width("\u{1A15}\u{1A17}\u{200D}\u{FE0E}", 1, 1)
  assert_str_width("\u{1A15}\u{1A17}\u{200D}\u{FE0F}", 1, 1)
  assert_str_width(
    "\u{1A15}\u{17B5}\u{200D}\u{FE0E}\u{1A17}\u{200D}\u{FE0F}\u{200D}\u{FE0F}", 1,
    1,
  )
  assert_str_width("\u{1A15}\u{1A15}\u{1A17}\u{200D}\u{1A10}", 2, 2)
  assert_str_width(
    "\u{1A15}\u{1A15}\u{1A17}\u{200D}\u{200D}\u{200D}\u{200D}\u{1A10}", 2, 2,
  )
  assert_str_width("\u{1A15}\u{1A17}\u{1A10}", 2, 2)
  assert_str_width("\u{1A15}\u{200D}\u{1A10}", 2, 2)
  assert_str_width("\u{1A15}\u{1A10}", 2, 2)
  assert_str_width("\u{1A15}\u{1A17}\u{1A17}\u{200D}\u{1A10}", 2, 2)
  assert_str_width("\u{1A15}\u{1A17}\u{338}\u{200D}\u{1A10}", 2, 2)
}

///|
test "test_tifinagh_biconsonants" {
  assert_str_width("\u{2D4F}", 1, 1)
  assert_str_width("\u{2D3E}", 1, 1)
  assert_str_width("\u{2D7F}", 1, 1)
  assert_str_width("\u{2D4F}\u{200D}\u{2D3E}", 1, 1)
  assert_str_width("\u{2D4F}\u{2D7F}\u{2D3E}", 1, 1)
  assert_str_width("\u{2D4F}\u{200D}\u{2D3E}", 1, 1)
  assert_str_width(
    "\u{2D4F}\u{FE0F}\u{200D}\u{2D7F}\u{FE0E}\u{200D}\u{17B5}\u{2D3E}", 1, 1,
  )
  assert_str_width("\u{2D4F}\u{301}\u{2D7F}\u{2D3E}", 3, 3)
  assert_str_width("\u{2D4F}\u{301}\u{200D}\u{2D3E}", 2, 2)
  assert_str_width("\u{2D4F}\u{2D3E}", 2, 2)
  assert_str_width("\u{2D4F}\u{2D7F}\u{2D7F}\u{2D3E}", 4, 4)
  assert_str_width("\u{2D7F}\u{2D3E}", 2, 2)
  assert_str_width("\u{2D7F}\u{2D7F}\u{2D66}", 3, 3)
  assert_str_width("\u{2D66}\u{2D7F}\u{2D3E}", 3, 3)
}

///|
test "test_old_turkic_ligature" {
  assert_str_width("\u{10C32}", 1, 1)
  assert_str_width("\u{10C03}", 1, 1)
  assert_str_width("\u{10C32}\u{10C03}", 2, 2)
  assert_str_width("\u{10C32}\u{200D}\u{10C03}", 1, 1)
  assert_str_width("\u{10C32}\u{FE0F}\u{200D}\u{FE0E}\u{10C03}", 1, 1)
  assert_str_width("\u{10C32}\u{2D7F}\u{10C03}", 3, 3)
  assert_str_width("\u{10C32}\u{301}\u{200D}\u{10C03}", 2, 2)
  assert_str_width("\u{10C03}\u{200D}\u{10C32}", 2, 2)
  assert_str_width("\u{200D}\u{10C32}", 1, 1)
}

///|
test "test_khmer_coeng" {
  assert_str_width("ល", 1, 1)
  assert_str_width("ង", 1, 1)
  assert_str_width("លង", 2, 2)
  assert_str_width("ល្ង", 1, 1)
  let khmer_chars = [
    '\u{1780}', '\u{1781}', '\u{1782}', '\u{1784}', '\u{1785}', '\u{1786}', '\u{1787}',
    '\u{1789}', '\u{178A}', '\u{178B}', '\u{178C}', '\u{178E}', '\u{178F}', '\u{1790}',
    '\u{1791}', '\u{1792}', '\u{1793}', '\u{1795}', '\u{1796}', '\u{1797}', '\u{1798}',
    '\u{179B}', '\u{179C}', '\u{179D}', '\u{17A0}', '\u{17A2}', '\u{17A7}', '\u{17AB}',
    '\u{17AC}', '\u{17AF}',
  ]
  for i in 0..<65536 {
    let c = i.unsafe_to_char()
    let is_khmer = khmer_chars.contains(c)
    if is_khmer {
      assert_str_width("\u{17D2}\{c}", 0, 0)
      assert_str_width("\u{17D2}\u{200D}\u{200D}\{c}", 0, 0)
    } else {
      assert_str_width(
        "\u{17D2}\{c}",
        @width.char(c, cjk=false).unwrap_or(1),
        @width.char(c, cjk=true).unwrap_or(1),
      )
    }
  }
}

///|
test "test_khmer_qaa" {
  assert_str_width("\u{17A4}", 2, 2)
  assert_str_width("\u{17A2}\u{17A6}", 2, 2)
}

///|
test "test_khmer_sign_beyyal" {
  assert_str_width("\u{17D8}", 3, 3)
  assert_str_width("\u{17D4}\u{179B}\u{17D4}", 3, 3)
}

///|
test "test_emoji_modifier" {
  assert_str_width("\u{1F46A}", 2, 2)
  assert_str_width("\u{1F3FB}", 2, 2)
  assert_str_width("\u{1F46A}\u{1F3FB}", 2, 2)
  assert_str_width("\u{1F46A}\u{200D}\u{200D}\u{1F3FB}", 4, 4)
}

///|
test "test_emoji_zwj" {
  assert_str_width("🧑‍🤝‍🧑", 2, 2)
  assert_str_width("🇮🇱🕊️🇵🇸", 6, 6)
  assert_str_width("🇵🇸\u{200D}🕊️\u{200D}🇮🇱", 2, 2)
  assert_str_width("🇮🇱\u{200D}🕊️\u{200D}\u{200D}🇵🇸", 4, 4)
  assert_str_width("🇵🇸\u{200D}\u{200D}🕊️\u{200D}🇮🇱", 4, 4)
  assert_str_width("🇦🇦\u{200D}🇦🇦", 2, 2)
  assert_str_width("🇦🇦\u{200D}🇦🇦🇦", 3, 3)
  assert_str_width("🇦🇦\u{200D}\u{200D}🇦🇦", 4, 4)
  assert_str_width("🇦🇦\u{200D}🇦\u{200D}🇦🇦", 5, 5)
  assert_str_width("🇦🇦\u{200D}🇦🇦\u{200D}🇦🇦", 2, 2)
  assert_str_width("🇦🇦\u{200D}🇦🇦🇦\u{200D}🇦🇦", 5, 5)
  assert_str_width("🇦🇦\u{200D}🇦🇦🇦🇦\u{200D}🇦🇦", 4, 4)
  assert_str_width("🇦🇦\u{200D}🇦🇦🇦🇦🇦\u{200D}🇦🇦", 7, 7)
  assert_str_width(
    "🇦🇦\u{200D}🇦🇦🇦🇦🇦🇦\u{200D}🇦🇦", 6, 6,
  )
  assert_str_width(
    "🇦🇦\u{200D}🇦🇦🇦🇦🇦🇦🇦\u{200D}🇦🇦", 9, 9,
  )
  assert_str_width("🏴󠁧󠁢󠁷󠁬󠁳󠁿", 2, 2)
  assert_str_width(
    "🏴󠁧󠁢󠁥󠁮󠁧󠁿\u{200D}🏴󠁧󠁢󠁳󠁣󠁴󠁿\u{200D}🏴󠁧󠁢󠁷󠁬󠁳󠁿",
    2, 2,
  )
  assert_str_width("🇦👪\u{200D}🏿", 3, 3)
  assert_str_width("🇦🏿\u{200D}🏿", 3, 3)
  assert_char_width('🏴', Some(2), Some(2))
  assert_str_width("\u{E0031}", 0, 0)
  assert_str_width("\u{E0063}", 0, 0)
  assert_str_width("\u{E007F}", 0, 0)
  assert_str_width("🏴\u{200D}Ⓜ️", 2, 2)
  assert_str_width("🏴\u{E0031}\u{200D}Ⓜ️", 4, 4)
  assert_str_width("🏴\u{E0063}\u{200D}Ⓜ️", 4, 4)
  assert_str_width("🏴\u{E007F}\u{200D}Ⓜ️", 4, 4)
  assert_str_width("🏴\u{E0031}\u{E007F}\u{200D}Ⓜ️", 4, 4)
  assert_str_width("🏴\u{E0031}\u{E0031}\u{E007F}\u{200D}Ⓜ️", 4, 4)
  assert_str_width(
    "🏴\u{E0031}\u{E0031}\u{E0031}\u{E007F}\u{200D}Ⓜ️", 2, 2,
  )
  assert_str_width(
    "🏴\u{E0031}\u{E0031}\u{E0031}\u{E0031}\u{E007F}\u{200D}Ⓜ️", 4, 4,
  )
  assert_str_width(
    "🏴\u{E0031}\u{E0031}\u{E0031}\u{E0063}\u{E007F}\u{200D}Ⓜ️", 2, 2,
  )
}

///|
test "test_kirat_rai_vowel_signs" {
  assert_str_width("\u{16D67}", 1, 1)
  assert_str_width("\u{16D68}", 1, 1)
  assert_str_width("\u{16D69}", 1, 1)
  assert_str_width("\u{16D63}", 1, 1)
  assert_str_width("\u{16D67}\u{16D67}", 2, 2)
}

///|
async test "emoji_test_file" {
  let file = @fs.read_file("readline/unicode/width/emoji-test.txt")
  for line in file.split("\n") {
    let cps = lexmatch line using longest {
        "" => continue
        ("#", _) => continue
        ((".*" as cps) ";[ \t\n]*" "(fully-qualified|component).*" "[ \t\n]*") =>
          cps
        _ => continue
      }
    let emoji = cps
      .trim(char_set=" \t\n")
      .split(" ")
      .map(s => (try? @strconv.parse_uint(s, base=16))
        .unwrap()
        .reinterpret_as_int()
        .unsafe_to_char())
      |> @string.from_iter
    assert_str_width(emoji, 2, 2)
  }
}

///|
test "ambiguous_line_break" {
  assert_str_width("\u{24EA}", 1, 2)
  assert_str_width("\u{2616}", 1, 2)
  assert_str_width("\u{2780}", 1, 2)
}

///|
test "test_vs1_vs2" {
  assert_str_width("\u{FE00}", 0, 0)
  assert_str_width("\u{FE01}", 0, 0)
  for i in 0..=0x10FFFF {
    let c = i.unsafe_to_char()
    if c is ('\u{2018}' | '\u{2019}' | '\u{201C}' | '\u{201D}') {
      assert_str_width(c.to_string(), 1, 2)
      assert_str_width("\{c}\u{FE00}", 1, 1)
      assert_str_width("\{c}\u{FE00}\u{FE01}", 1, 1)
      assert_str_width("\{c}\u{FE01}", 2, 2)
      assert_str_width("\{c}\u{FE01}\u{FE00}", 2, 2)
      continue
    }
    for cjk in [false, true] {
      assert_eq(
        @width.string("\{c}\u{FE00}", cjk~),
        @width.char(c, cjk~).unwrap_or(1),
      )
      assert_eq(
        @width.string("\{c}\u{FE01}", cjk~),
        @width.char(c, cjk~).unwrap_or(1),
      )
    }
  }
}
