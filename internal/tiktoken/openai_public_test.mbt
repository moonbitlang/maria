///|
test "cl100k_base" {
  let cl100k_base = @tiktoken.cl100k_base()
  @json.inspect(cl100k_base.encode("Hello, world!"), content=[9906, 11, 1917, 0])
  let tokens = cl100k_base.encode("你好，世界🌍")
  @json.inspect(tokens, content=[
    57668, 53901, 3922, 3574, 244, 98220, 9468, 234, 235,
  ])
  @json.inspect(cl100k_base.decode(tokens), content="你好，世界🌍")
}

///|
fn pcre2_cl100k_tokenize(string : String) -> Array[String] raise {
  let regex = @pcre2.compile(
    "'(?i:[sdmt]|ll|ve|re)|[^\\r\\n\\p{L}\\p{N}]?+\\p{L}++|\\p{N}{1,3}+| ?[^\\s\\p{L}\\p{N}]++[\\r\\n]*+|\\s++$|\\s*[\\r\\n]|\\s+(?!\\S)|\\s",
  )
  let matches = regex.matches(string)
  let tokens = []
  while matches.next() is Some(matched) {
    tokens.push(matched[0].to_string())
  }
  tokens
}

///|
test "cl100k_base" {
  let parameters : Json = {
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "The directory path to list files from",
      },
    },
    "required": ["path"],
  }
  for
    content in [
      "list_files",
      "List files in a directory",
      "The directory path to list files from",
      parameters.stringify(indent=2),
    ] {
    @json.inspect(
      pcre2_cl100k_tokenize(content),
      content=cl100k_base_tokenize_all(content).to_json(),
    )
  }
}
