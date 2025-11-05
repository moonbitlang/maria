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
/// Part 1: '(?i:[sdmt]|ll|ve|re)
/// 
///  Parse tree:
/// 
/// ```rust
/// 
///  ExprTree {
///     expr: Concat(
///         [
///             Literal {
///                 val: "'",
///                 casei: false,
///             },
///             Alt(
///                 [
///                     Delegate {
///                         inner: "[sdmt]",
///                         size: 1,
///                         casei: true,
///                     },
///                     Concat(
///                         [
///                             Literal {
///                                 val: "l",
///                                 casei: true,
///                             },
///                             Literal {
///                                 val: "l",
///                                 casei: true,
///                             },
///                         ],
///                     ),
///                     Concat(
///                         [
///                             Literal {
///                                 val: "v",
///                                 casei: true,
///                             },
///                             Literal {
///                                 val: "e",
///                                 casei: true,
///                             },
///                         ],
///                     ),
///                     Concat(
///                         [
///                             Literal {
///                                 val: "r",
///                                 casei: true,
///                             },
///                             Literal {
///                                 val: "e",
///                                 casei: true,
///                             },
///                         ],
///                     ),
///                 ],
///             ),
///         ],
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
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
/// Part 2: [^\r\n\p{L}\p{N}]?+\p{L}++
/// Parse tree:
/// 
/// ```rust 
/// ExprTree {
///     expr: Concat(
///         [
///             AtomicGroup(
///                 Repeat {
///                     child: Delegate {
///                         inner: "[^\r\n\\p{L}\\p{N}]",
///                         size: 1,
///                         casei: false,
///                     },
///                     lo: 0,
///                     hi: 1,
///                     greedy: true,
///                 },
///             ),
///             AtomicGroup(
///                 Repeat {
///                     child: Delegate {
///                         inner: "\\p{L}",
///                         size: 1,
///                         casei: false,
///                     },
///                     lo: 1,
///                     hi: 4294967295,
///                     greedy: true,
///                 },
///             ),
///         ],
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
fn cl100k_base_tokenize_part2(
  input : StringView,
) -> StringView raise BackTracing {
  fn predicate(ch : Char) -> Bool {
    ch != '\u{000D}' && ch != '\n' && !is_alphabetic(ch) && !is_number(ch)
  }

  let (non_letter_len, remaining_input) = match input {
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
    try! input[0:non_letter_len + letter_len]
  }
}

///|
/// Part 3: \p{N}{1,3}+
/// 
/// Parse tree:
/// ```rust 
/// ExprTree {
///     expr: AtomicGroup(
///         Repeat {
///             child: Delegate {
///                 inner: "\\p{N}",
///                 size: 1,
///                 casei: false,
///             },
///             lo: 1,
///             hi: 3,
///             greedy: true,
///         },
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
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
// Part 4: [ ]?[^\s\p{L}\p{N}]++[\r\n]*+

///|
/// ```rust 
/// ExprTree {
///     expr: Concat(
///         [
///             Repeat {
///                 child: Delegate {
///                     inner: "[ ]",
///                     size: 1,
///                     casei: false,
///                 },
///                 lo: 0,
///                 hi: 1,
///                 greedy: true,
///             },
///             AtomicGroup(
///                 Repeat {
///                     child: Delegate {
///                         inner: "[^\\s\\p{L}\\p{N}]",
///                         size: 1,
///                         casei: false,
///                     },
///                     lo: 1,
///                     hi: 4294967295,
///                     greedy: true,
///                 },
///             ),
///             AtomicGroup(
///                 Repeat {
///                     child: Delegate {
///                         inner: "[\r\n]",
///                         size: 1,
///                         casei: false,
///                     },
///                     lo: 0,
///                     hi: 4294967295,
///                     greedy: true,
///                 },
///             ),
///         ],
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
fn cl100k_base_tokenize_part4(
  input : StringView,
) -> StringView raise BackTracing {
  fn predicate(ch : Char) -> Bool {
    !is_whitespace(ch) && !is_alphabetic(ch) && !is_number(ch)
  }

  // Step 1: Optional space character [ ]?
  let (consumed_space_len, rest) = match input {
    [' ', .. rest] => (1, rest) // Consume optional space
    _ => (0, input) // No space, continue with original string
  }

  // Step 2: One or more non-whitespace/non-letter/non-number characters [^\s\p{L}\p{N}]++
  let (non_ws_len, rest2) = loop (0, rest) {
    (len, [ch, .. rest]) if predicate(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, rest) => break (len, rest)
  }

  // Must have at least one character matching the predicate (++ means possessive one-or-more)
  if non_ws_len == 0 {
    raise BackTracing
  }

  // Step 3: Zero or more \r\n characters [\r\n]*+
  let newline_len = loop (0, rest2) {
    (len, [ch, .. rest]) if ch == '\u{000D}' || ch == '\n' =>
      continue (len + ch.utf16_len(), rest)
    (len, _) => break len
  }

  // Total length includes all parts
  let total_len = consumed_space_len + non_ws_len + newline_len
  try! input[0:total_len]
}

///|
/// Part 5: \s++$
/// 
/// ```rust
/// ExprTree {
///     expr: Concat(
///         [
///             AtomicGroup(
///                 Repeat {
///                     child: Delegate {
///                         inner: "\\s",
///                         size: 1,
///                         casei: false,
///                     },
///                     lo: 1,
///                     hi: 4294967295,
///                     greedy: true,
///                 },
///             ),
///             Assertion(
///                 EndText,
///             ),
///         ],
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
fn cl100k_base_tokenize_part5(
  input : StringView,
) -> StringView raise BackTracing {
  // \s++$ means one or more whitespace characters at the end of string (possessive)
  let len = loop (0, input) {
    (len, [ch, .. rest]) if is_whitespace(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, []) => break len // end of string
    (_, _) => break 0 // non-whitespace found, not at end
  }
  if len == 0 || len < input.length() {
    // Either no whitespace found or not at end of string
    raise BackTracing
  } else {
    try! input[0:len]
  }
}

///|
/// Part 6: \s*[\r\n]
/// ```rust 
/// ExprTree {
///     expr: Concat(
///         [
///             Repeat {
///                 child: Delegate {
///                     inner: "\\s",
///                     size: 1,
///                     casei: false,
///                 },
///                 lo: 0,
///                 hi: 4294967295,
///                 greedy: true,
///             },
///             Delegate {
///                 inner: "[\r\n]",
///                 size: 1,
///                 casei: false,
///             },
///         ],
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
/// 
fn cl100k_base_tokenize_part6(
  input : StringView,
) -> StringView raise BackTracing {
  // \s*[\r\n] means zero or more whitespace followed by \r or \n
  let ws_len = loop (0, input) {
    (len, [ch, .. rest]) if is_whitespace(ch) =>
      continue (len + ch.utf16_len(), rest)
    (len, _) => break len
  }
  let last_ch = input.get_char(ws_len - 1)
  match last_ch {
    Some(ch) if ch == '\n' || ch == '\r' => try! input[0:ws_len]
    _ => raise BackTracing
  }
}

///|
/// Part 7: \s+(?!\S)
/// ```rust
/// ExprTree {
///     expr: Concat(
///         [
///             Repeat {
///                 child: Delegate {
///                     inner: "\\s",
///                     size: 1,
///                     casei: false,
///                 },
///                 lo: 1,
///                 hi: 4294967295,
///                 greedy: true,
///             },
///             LookAround(
///                 Delegate {
///                     inner: "\\S",
///                     size: 1,
///                     casei: false,
///                 },
///                 LookAheadNeg,
///             ),
///         ],
///     ),
///     backrefs: {},
///     named_groups: {},
///     contains_subroutines: false,
///     self_recursive: false,
/// }
/// ```
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
