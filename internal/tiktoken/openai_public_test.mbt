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
test "bench_cl100k_base" (b : @bench.T) {
  let text = @fs.read_file_to_string("bench/messages.json")
  let cl100k_base = @tiktoken.cl100k_base()
  b.bench(() => try! ignore(cl100k_base.encode(text)))
}
