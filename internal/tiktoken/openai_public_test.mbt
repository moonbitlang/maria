///|
test "cl100k_base" {
  let cl100k_base = @tiktoken.cl100k_base()
  json_inspect(cl100k_base.encode("Hello, world!"), content=[9906, 11, 1917, 0])
  let tokens = cl100k_base.encode("你好，世界🌍")
  json_inspect(tokens, content=[
    57668, 53901, 3922, 3574, 244, 98220, 9468, 234, 235,
  ])
  json_inspect(cl100k_base.decode(tokens), content="你好，世界🌍")
}
