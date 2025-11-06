///|
test "bench-tokenize" (b : @bench.T) {
  let param = @openai.chat_completion(
    model="gpt-4-0613",
    messages=@json.from_json(messages),
  )
  let counter = @token.Counter::new()
  b.bench(name="pcre2", () => ignore(counter.count_param(param)) catch {
    _ => ()
  })
}
