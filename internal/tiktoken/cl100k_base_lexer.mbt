///|
///
/// cl100k_base lexer rule: https://github.com/openai/tiktoken/blob/97e49cbadd500b5cc9dbb51a486f0b42e6701bee/tiktoken_ext/openai_public.py#L89
///
/// This regex pattern is used [fancy-regex](https://fancy-regex.github.io/fancy-regex/) as regex engine.
/// 
/// r"""'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}++|\p{N}{1,3}+| ?[^\s\p{L}\p{N}]++[\r\n]*+|\s++$|\s*[\r\n]|\s+(?!\S)|\s"""
///
///
///
/// Pattern parts using | alternatives:
///
/// Part 1: '(?i:[sdmt]|ll|ve|re)
/// Part 2: [^\r\n\p{L}\p{N}]?+\p{L}++
/// Part 3: \p{N}{1,3}+
/// Part 4: ?[^\s\p{L}\p{N}]++[\r\n]*+
/// Part 5: \s++$
/// Part 6: \s*[\r\n]
/// Part 7: \s+(?!\S)
/// Part 8: \s
///

///|
/// used for `\p{L}``
using @unicode {is_alphabetic}

///|
/// used for `\p{N}`
using @unicode {is_number}

///|
/// used for `\s`
using @unicode {is_whitespace}

///|
priv suberror BackTracing derive(Show, ToJson)

///|
/// parse English common contractions
/// 
/// Part 1: '(?i:[sdmt]|ll|ve|re)
fn cl100k_base_tokenize_part1(
  input : StringView,
) -> StringView raise BackTracing {
  lexmatch input {
    // "sdmt" case insensitive
    ("'s" as matched, _) => matched
    ("'S" as matched, _) => matched
    ("'d" as matched, _) => matched
    ("'D" as matched, _) => matched
    ("'m" as matched, _) => matched
    ("'M" as matched, _) => matched
    ("'t" as matched, _) => matched
    ("'T" as matched, _) => matched
    // "ll", "ve", "re" case sensitive
    ("'ll" as matched, _) => matched
    ("'ve" as matched, _) => matched
    ("'re" as matched, _) => matched
    // no match
    _ => raise BackTracing
  }
}

///|
/// parse non-common characters prefix and letters using possessive semantics.
/// 
/// Not need possessive semantics, because no following overlapping pattern.
/// 
/// Part 2: [^\r\n\p{L}\p{N}]?+\p{L}++
fn cl100k_base_tokenize_part2(
  input : StringView,
) -> StringView raise BackTracing {
  fn predicate(ch : Char) -> Bool {
    ch != '\u{000D}' && ch != '\n' && !is_alphabetic(ch) && !is_number(ch)
  }

  let (non_common_len, remaining_input) = match input {
    [ch, .. rest] if predicate(ch) => (ch.utf16_len(), rest)
    rest => (0, rest)
  }
  let letter_len = loop (0, remaining_input) {
    (len, [ch, .. rest]) if is_alphabetic(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, _) => break len
  }
  if letter_len == 0 {
    raise BackTracing
  } else {
    try! input[0:non_common_len + letter_len]
  }
}

///|
/// parse number with length 1 to 3 using possessive semantics.
/// 
/// Not need possessive semantics, because no following overlapping pattern.
/// 
/// Part 3: \p{N}{1,3}+
fn cl100k_base_tokenize_part3(
  input : StringView,
) -> StringView raise BackTracing {
  let len = loop (0, 0, input) {
    (len, count, [ch, .. rest]) if count < 3 && is_number(ch) =>
      continue (len + ch.utf16_len(), count + 1, rest)
    (len, count, _) => break (len, count)
  }
  let (final_len, count) = len
  if count >= 1 {
    try! input[0:final_len]
  } else {
    raise BackTracing
  }
}

///|
/// 1. optional space 
/// 2. non-common character 
/// 3. end of lines
/// 
/// Not need possessive semantics, because no following overlapping pattern.
/// 
/// Part 4: [ ]?[^\s\p{L}\p{N}]++[\r\n]*+
fn cl100k_base_tokenize_part4(
  input : StringView,
) -> StringView raise BackTracing {
  fn predicate(ch : Char) -> Bool {
    !is_whitespace(ch) && !is_alphabetic(ch) && !is_number(ch)
  }
  // part 1: optional space
  let (consumed_space_len, rest) = match input {
    [' ', .. rest] => (1, rest)
    _ => (0, input)
  }
  // part 2: non-common character(s)
  let (non_ws_len, rest2) = loop (0, rest) {
    (len, [ch, .. rest]) if predicate(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, rest) => break (len, rest)
  }
  // fast fail for quantifier requirement
  if non_ws_len == 0 {
    raise BackTracing
  }

  // part 3: end of lines
  let newline_len = loop (0, rest2) {
    (len, [ch, .. rest]) if ch == '\r' || ch == '\n' =>
      continue (len + ch.utf16_len(), rest)
    (len, _) => break len
  }
  let len = consumed_space_len + non_ws_len + newline_len
  try! input[0:len]
}

///|
/// parse whitespace at end of string.
/// 
/// Not need possessive semantics, because no following overlapping pattern.
/// 
/// Part 5: \s++$
fn cl100k_base_tokenize_part5(
  input : StringView,
) -> StringView raise BackTracing {
  let len = loop (0, input) {
    (len, [ch, .. rest]) if is_whitespace(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, []) => break len
    (_, _) => break 0
  }
  if len == 0 || len < input.length() {
    raise BackTracing
  } else {
    try! input[0:len]
  }
}

///|
/// parse whitespace but last whitespace must be end of line.
/// 
/// Need backtracking for greedy semantics.
/// 
/// Part 6: \s*[\r\n]
fn cl100k_base_tokenize_part6(
  input : StringView,
) -> StringView raise BackTracing {
  let ws_len = loop (0, input) {
    (len, [ch, .. rest]) if is_whitespace(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, _) => break len
  }
  let prefix = try! input[0:ws_len]
  // greedy kleene start
  let back_len = loop (0, prefix) {
    (len, [.., ch]) if ch == '\n' || ch == '\r' => break len
    (len, [.. pf, _]) => continue (len + 1, pf)
    (len, []) => break len
  }
  let actual_len = ws_len - back_len
  if actual_len >= 1 {
    try! input[0:actual_len]
  } else {
    raise BackTracing
  }
}

///|
/// parse whitespace follow whitespace(not non-whitespace). 
/// 
/// Part 7: \s+(?!\S)
fn cl100k_base_tokenize_part7(
  input : StringView,
) -> StringView raise BackTracing {
  let len = loop (0, input) {
    (len, [ch, lookahead, ..] as all) if is_whitespace(ch) &&
      is_whitespace(lookahead) =>
      continue (len + ch.utf16_len(), try! all[ch.utf16_len():])
    (len, _) => break len
  }
  if len == 0 {
    raise BackTracing
  } else {
    try! input[0:len]
  }
}

///|
// Part 8: \s
fn cl100k_base_tokenize_part8(
  input : StringView,
) -> StringView raise BackTracing {
  // \s means exactly one whitespace character
  match input {
    [ch, ..] if is_whitespace(ch) => try! input[0:ch.utf16_len()]
    _ => raise BackTracing
  }
}

///|
let cl100k_base_parts : ReadOnlyArray[
  (StringView) -> StringView raise BackTracing,
] = [
  cl100k_base_tokenize_part1, cl100k_base_tokenize_part2, cl100k_base_tokenize_part3,
  cl100k_base_tokenize_part4, cl100k_base_tokenize_part5, cl100k_base_tokenize_part6,
  cl100k_base_tokenize_part7, cl100k_base_tokenize_part8,
]

///|
// r"""'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}++|\p{N}{1,3}+| ?[^\s\p{L}\p{N}]++[\r\n]*+|\s++$|\s*[\r\n]|\s+(?!\S)|\s"""
pub fn cl100k_base_tokenize(input : StringView) -> StringView? {
  for part in cl100k_base_parts {
    try {
      return Some(part(input))
    } catch {
      BackTracing => continue
    }
  } else {
    return None // No part matched
  }
}

///|
/// use `tokenize` function to tokenize entire string
/// if error then use `Panic Mode` to skip one character and continue
/// until the entire string is processed
///
pub fn cl100k_base_tokenize_all(input : StringView) -> Array[StringView] {
  let tokens : Array[StringView] = []
  let mut remaining = input
  while remaining.length() > 0 {
    match cl100k_base_tokenize(remaining) {
      Some(token) => {
        tokens.push(token)
        remaining = try! remaining[token.length():]
      }
      // Panic mode: skip one character and continue
      None =>
        match remaining.get_char(0) {
          None => abort("impossible, unexpected Unicode error")
          Some(ch) => remaining = try! remaining[ch.utf16_len():]
        }
    }
  }
  tokens
}
