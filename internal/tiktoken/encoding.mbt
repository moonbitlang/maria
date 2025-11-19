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
  Pcre2(@pcre2.Code)
}

///|
pub fn Pattern::cl100k_base() -> Pattern {
  Cl100kBase
}

///|
pub fn Pattern::pcre2(pat_str : String) -> Pattern raise {
  Pcre2(@pcre2.compile(pat_str))
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
pub fn Encoding::encode(
  self : Encoding,
  piece : StringView,
) -> Array[Int] raise {
  let tokens = []
  match self.pattern {
    Cl100kBase =>
      for matches in cl100k_base_tokenize_all(piece) {
        self.encode_piece(tokens, matches)
      }
    Pcre2(regex) => {
      let matches = regex.matches(piece)
      while matches.next() is Some(matched) {
        self.encode_piece(tokens, matched[0])
      }
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
