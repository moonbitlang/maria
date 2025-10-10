///|
pub fn cl100k_base() -> Encoding raise {
  let mergeable_ranks = {}
  for line in cl100k_base_mergeable_ranks.split("\n") {
    if line is "" {
      continue
    }
    guard line.split(" ").collect() is [token, rank]
    let token = @base64.decode(token.to_string())
    mergeable_ranks[token] = @strconv.parse_int(rank)
  }
  let special_tokens = {
    "<|endoftext|>": 100257,
    "<|fim_prefix|>": 100258,
    "<|fim_middle|>": 100259,
    "<|fim_suffix|>": 100260,
    "<|endofprompt|>": 100276,
  }
  let pat_str = "'(?i:[sdmt]|ll|ve|re)|[^\\r\\n\\p{L}\\p{N}]?+\\p{L}++|\\p{N}{1,3}+| ?[^\\s\\p{L}\\p{N}]++[\\r\\n]*+|\\s++$|\\s*[\\r\\n]|\\s+(?!\\S)|\\s"
  Encoding::new(mergeable_ranks~, special_tokens~, pat_str~)
}
