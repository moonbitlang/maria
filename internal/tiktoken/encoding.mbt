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
  let bytes = tokens.map(t => self.decoder.at(t))
  let len = bytes.iter().map(b => b.length()).fold(init=0, Int::add)
  let buffer = @buffer.new(size_hint=len)
  let indexes = [0]
  for i = 0; i < bytes.length(); i = i + 1 {
    buffer.write_bytes(bytes[i])
    indexes.push(indexes.last().unwrap() + bytes[i].length())
  }
  let bytes = buffer.to_bytes()
  let rank = Array::make(tokens.length() - 1, @int.max_value)
  for i = 0; i < rank.length(); i = i + 1 {
    if self.encoder.get_from_bytes(bytes[indexes[i]:indexes[i + 2]])
      is Some(token) {
      rank[i] = token
    }
  }
  let mut index = arg_min(rank)
  while index != -1 {
    indexes.remove(index + 1) |> ignore
    tokens[index] = rank[index]
    tokens.remove(index + 1) |> ignore()
    rank.remove(index) |> ignore()
    // merge left
    if index > 0 {
      rank[index - 1] = self.encoder
        .get_from_bytes(bytes[indexes[index - 1]:indexes[index + 1]])
        .unwrap_or(@int.max_value)
    }
    // merge right
    if index < rank.length() {
      rank[index] = self.encoder
        .get_from_bytes(bytes[indexes[index]:indexes[index + 2]])
        .unwrap_or(@int.max_value)
    }
    index = arg_min(rank)
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
