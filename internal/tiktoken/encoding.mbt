///|
struct Encoding {
  encoder : Map[Bytes, Int]
  decoder : FixedArray[Bytes]
  special_encoder : Map[String, Int]
  special_decoder : Map[Int, Bytes]
  pattern : Pattern
}

///|
pub enum Pattern {
  Cl100kBase
}

///|
pub fn Pattern::cl100k_base() -> Pattern {
  Cl100kBase
}

///|
pub fn Encoding::new(
  mergeable_ranks~ : Map[Bytes, Int],
  special_tokens~ : Map[String, Int],
  pattern~ : Pattern,
) -> Encoding {
  let encoder : Map[Bytes, Int] = {}
  let decoder = FixedArray::make(mergeable_ranks.length(), b"")
  for piece, rank in mergeable_ranks {
    encoder[piece] = rank
    decoder[rank] = piece
  }
  let special_encoder = {}
  let special_decoder = {}
  for token, rank in special_tokens {
    special_encoder[token] = rank
    special_decoder[rank] = @encoding/utf8.encode(token)
  }
  Encoding::{ encoder, decoder, special_encoder, special_decoder, pattern }
}

///|
pub fn Encoding::special_tokens(self : Encoding, piece : String) -> Int? {
  self.special_encoder.get(piece)
}

///|
fn arg_min(vec : Array[Int]) -> Int {
  let mut value = @int.max_value
  let mut index = -1
  for i = 0; i < vec.length(); i = i + 1 {
    if vec[i] < value {
      value = vec[i]
      index = i
    }
  }
  index
}

///|
fn Encoding::lookup(
  self : Encoding,
  piece : Bytes,
  tokens : Array[Int],
) -> Unit {
  for b in piece {
    let token = match self.encoder.get([b]) {
      Some(index) => index
      None => @int.max_value
    }
    tokens.push(token)
  }
}

///|
fn Encoding::merge(self : Encoding, tokens : Array[Int]) -> Unit {
  let pieces = tokens.map(t => self.decoder[t])
  let rank = Array::make(pieces.length() - 1, @int.max_value)
  for i = 0; i < pieces.length() - 1; i = i + 1 {
    let l = pieces[i]
    let r = pieces[i + 1]
    if self.encoder.get(l + r) is Some(token) {
      rank[i] = token
    }
  }
  let mut index = arg_min(rank)
  while index != -1 {
    let merge = pieces[index] + pieces[index + 1]
    pieces[index] = merge
    pieces.remove(index + 1) |> ignore()
    let merge_token = self.encoder.at(merge)
    tokens[index] = merge_token
    tokens.remove(index + 1) |> ignore()
    rank.remove(index) |> ignore()
    // merge left
    if index > 0 {
      let l = pieces[index - 1]
      let r = pieces[index]
      if self.encoder.get(l + r) is Some(token) {
        rank[index - 1] = token
      } else {
        rank[index - 1] = @int.max_value
      }
    }
    // merge right
    if index < pieces.length() - 1 {
      let l = pieces[index]
      let r = pieces[index + 1]
      if self.encoder.get(l + r) is Some(token) {
        rank[index] = token
      } else {
        rank[index] = @int.max_value
      }
    }
    index = arg_min(rank)
  }
}

///|
fn Encoding::encode_piece(
  self : Encoding,
  tokens : Array[Int],
  piece : StringView,
) -> Unit {
  let piece = @encoding/utf8.encode(piece)
  match self.encoder.get(piece) {
    Some(token) => tokens.push(token)
    None => {
      let t = []
      self.lookup(piece, t)
      self.merge(t)
      tokens.append(t)
    }
  }
}

///|
/// There are three regex patterns to split text into pieces.
///
/// - `cl100k_base`
/// - `r50k`
/// - `o200k_base`
/// 
/// The main purpose of these regexes is only for English text splitting.
/// 
/// 1. Enclitics, e.g. 's, 't, Warning: `r50k` is case-sensitive, both `cl100k_base` and `o200k_base` are case-insensitive.
/// 2. letters with optional leading 1 space, Warning: `cl100k_base` and `o200k_base` start with non-letter and non-digit, `o200k_base`'s letter pattern is more refined to distinguish upper case and lower case letters.
/// 3. integer with optional leading 1 space, Warning: `r50k` has no limit on digits, but others limit to 1-3 digits.
/// 4. non-letter and non-digit with optional leading 1 space, Warning: this is not very friendly to CJK characters, this split algorithm is too rough, highly relying on the transformer model's ability to handle such cases.
/// 5. space excluding last space (except end of text) 
/// 
/// `cl100k_base` and `o200k_base` also handle end of line characters for semantic text splitting.
/// 
/// These regex patterns seem to be a quick and dirty solution in `openai/tiktoken`'s early stage, but retraining the model is too costly.
/// Blame the OpenAI Python developers who didn't consider regex maintainability and performance—none of the regexes, and regex not work well for edge cases.
/// 
/// To improve performance, Rust developers use `fancy-regex` and multi-threading instead of the `regex` Python module (whose underlying implementation is `mrab-regex`) used by previous Python developers.
/// 
/// Some Rust developers rewrote these regexes and replaced `fancy-regex` with the `regex` crate—6x speed up in [openai/tiktoken#331](https://github.com/openai/tiktoken/pull/331), but no one dares to merge it due to potential risk.
/// 
/// This is a classic tech debt story: OpenAI in the early stage couldn't predict they would succeed so well, 
/// and in the later development stage, they became path dependent on the regex solution instead of adopting a more robust text splitting solution.

///|
let cl100k_base_regex : @regexp.Regexp = try! @regexp.compile(
  (
    #|'(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]+[\r\n]*|\s+$|\s*[\r\n]|\s+(?<Assertion>\s)|\s
  ),
)

///|
let r50k_regex : @regexp.Regexp = try! @regexp.compile(
  (
    #|'(?:[sdmt]|ll|ve|re)| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+$|\s+(?<Assertion>\s)|\s
  ),
)

///|
let o200k_base_regex : @regexp.Regexp = try! @regexp.compile(
  [
    (
      #|[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]*[\p{Ll}\p{Lm}\p{Lo}\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?
    ),
    (
      #|[^\r\n\p{L}\p{N}]?[\p{Lu}\p{Lt}\p{Lm}\p{Lo}\p{M}]+[\p{Ll}\p{Lm}\p{Lo}\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?
    ),
    (
      #|\p{N}{1,3}
    ),
    (
      #| ?[^\s\p{L}\p{N}]+[\r\n/]*
    ),
    (
      #|\s*[\r\n]+
    ),
    (
      #|\s+((?<Assertion>\s)|$)
    ),
    (
      #|\s+
    ),
  ].join("|"),
)

///|
pub fn Encoding::encode(self : Encoding, piece : StringView) -> Array[Int] {
  let tokens = []
  match self.pattern {
    Cl100kBase =>
      for matches in regexp_search_all(cl100k_base_regex, piece) {
        self.encode_piece(tokens, matches)
      }
  }
  tokens
}

///|
suberror DecodingError {
  InvalidToken(Int)
  MalformedUtf8(Bytes)
} derive(Show)

///|
pub fn Encoding::decode(
  self : Encoding,
  tokens : ArrayView[Int],
) -> String raise DecodingError {
  let buffer = @buffer.new()
  for token in tokens {
    if token >= 0 && token < self.decoder.length() {
      let piece = self.decoder[token]
      if piece.length() > 0 {
        buffer.write_bytes(piece)
        continue
      }
    }
    if self.special_decoder.get(token) is Some(piece) {
      buffer.write_bytes(piece)
      continue
    }
    raise DecodingError::InvalidToken(token)
  }
  let contents = buffer.contents()
  @encoding/utf8.decode(contents) catch {
    _ => raise DecodingError::MalformedUtf8(contents)
  }
}
