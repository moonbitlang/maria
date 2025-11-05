///|
struct Encoding {
  encoder : Map[Bytes, Int]
  decoder : Map[Int, Bytes]
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
  let decoder = {}
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
  let encoded = tokens.map(t => self.decoder.at(t))
  let rank = Array::make(encoded.length() - 1, @int.max_value)
  for i = 0; i < encoded.length() - 1; i = i + 1 {
    let l = encoded[i]
    let r = encoded[i + 1]
    if self.encoder.get(l + r) is Some(index) {
      rank[i] = index
    }
  }
  let mut min = arg_min(rank)
  while min != -1 {
    let merge = encoded[min] + encoded[min + 1]
    encoded[min] = merge
    encoded.remove(min + 1) |> ignore()
    let merge_token = self.encoder.at(merge)
    tokens[min] = merge_token
    tokens.remove(min + 1) |> ignore()
    rank.remove(min) |> ignore()
    // merge left
    if min > 0 {
      let l = encoded[min - 1]
      let r = encoded[min]
      if self.encoder.get(l + r) is Some(index) {
        rank[min - 1] = index
      } else {
        rank[min - 1] = @int.max_value
      }
    }
    // merge right
    if min < encoded.length() - 1 {
      let l = encoded[min]
      let r = encoded[min + 1]
      if self.encoder.get(l + r) is Some(index) {
        rank[min] = index
      } else {
        rank[min] = @int.max_value
      }
    }
    min = arg_min(rank)
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
        let piece = @encoding/utf8.encode(matches)
        match self.encoder.get(piece) {
          Some(token) => tokens.push(token)
          None => {
            self.lookup(piece, tokens)
            self.merge(tokens)
          }
        }
      }
    Pcre2(regex) => {
      let matches = regex.matches(piece)
      while matches.next() is Some(matched) {
        let piece = @encoding/utf8.encode(matched[0])
        match self.encoder.get(piece) {
          Some(token) => tokens.push(token)
          None => {
            self.lookup(piece, tokens)
            self.merge(tokens)
          }
        }
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
    if self.decoder.get(token) is Some(piece) {
      buffer.write_bytes(piece)
      continue
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
