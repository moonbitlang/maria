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
test "cl100k_base/pcre2" (t : @test.T) {
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
  let parameters = parameters.stringify(indent=2)
  let cl100k_base = @tiktoken.cl100k_base(pcre2=true)
  let tokens = cl100k_base.encode(parameters)
  for token in tokens {
    t.writeln(token)
  }
  t.snapshot(filename="cl100k_base_tokens.txt")
}

///|
test "cl100k_base/illusory0x0" (t : @test.T) {
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
  let parameters = parameters.stringify(indent=2)
  let cl100k_base = @tiktoken.cl100k_base(pcre2=false)
  let tokens = cl100k_base.encode(parameters)
  for token in tokens {
    t.writeln(token)
  }
  t.snapshot(filename="cl100k_base_tokens.txt")
}
