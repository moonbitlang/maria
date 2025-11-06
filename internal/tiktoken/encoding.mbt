///|
struct Encoding {
  encoder : Trie
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
priv struct Trie {
  mut value : Int
  children : FixedArray[Trie?]
}

///|
fn Trie::new() -> Trie {
  Trie::{ value: @int.max_value, children: FixedArray::make(256, None) }
}

///|
#alias("_[_]=_")
fn Trie::set(trie : Self, bytes : BytesView, value : Int) -> Unit {
  let mut trie = trie
  loop bytes {
    [] => trie.value = value
    [b, .. rest] => {
      let child = match trie.children[b.to_int()] {
        Some(t) => t
        None => {
          let t = Trie::new()
          trie.children[b.to_int()] = Some(t)
          t
        }
      }
      trie = child
      continue rest
    }
  }
}

///|
fn Trie::next(trie : Self, bytes : BytesView) -> Trie? {
  let mut trie = trie
  loop bytes {
    [] => return Some(trie)
    [b, .. rest] => {
      match trie.children[b.to_int()] {
        Some(t) => trie = t
        _ => return None
      }
      continue rest
    }
  }
}

///|
fn Trie::get(trie : Self, bytes : BytesView) -> Int? {
  if trie.next(bytes) is Some(t) && t.value != @int.max_value {
    Some(t.value)
  } else {
    None
  }
}

///|
pub fn Encoding::new(
  mergeable_ranks~ : Map[Bytes, Int],
  special_tokens~ : Map[String, Int],
  pattern~ : Pattern,
) -> Encoding {
  let encoder = Trie::new()
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
  let tries = Array::make(tokens.length() - 1, Some(self.encoder))
  let rank = Array::make(tokens.length() - 1, @int.max_value)
  let span = Array::makei(tokens.length() - 1, i => i + 2)
  for i = 0; i < rank.length(); i = i + 1 {
    for bytes in bytes[i:span[i]] {
      if tries[i] is Some(trie) && trie.next(bytes) is Some(t) {
        tries[i] = Some(t)
        rank[i] = t.value
      } else {
        tries[i] = None
        rank[i] = @int.max_value
        break
      }
    }
  }
  let mut index = arg_min(rank)
  while index != -1 {
    tokens[index] = rank[index]
    tokens.remove(index + 1) |> ignore()
    // merge left
    if index > 0 {
      for bytes in bytes[span[index - 1]:span[index]] {
        if tries[index - 1] is Some(trie) && trie.next(bytes) is Some(t) {
          tries[index - 1] = Some(t)
          rank[index - 1] = t.value
        } else {
          tries[index - 1] = None
          rank[index - 1] = @int.max_value
          break
        }
      }
      span[index - 1] = span[index]
    }
    // merge right
    if index == rank.length() - 1 {
      // nothing to the right
      span.remove(index) |> ignore
      rank.remove(index) |> ignore
      tries.remove(index) |> ignore
    } else {
      for bytes in bytes[span[index]:span[index + 1]] {
        if tries[index] is Some(trie) && trie.next(bytes) is Some(t) {
          tries[index] = Some(t)
          rank[index] = t.value
        } else {
          tries[index] = None
          rank[index] = @int.max_value
          break
        }
      }
      span[index] = span[index + 1]
      span.remove(index + 1) |> ignore
      rank.remove(index + 1) |> ignore
      tries.remove(index + 1) |> ignore
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
