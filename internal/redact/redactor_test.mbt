///|
test "text" {
  let redactor = @redact.Redactor::new()
  redactor.add_string("secret_token", "[REDACTED]")
  redactor.add_regexp(
    @regexp.compile(
      (
        #|\b\d{4}-\d{4}-\d{4}-\d{4}\b
      ),
    ),
    "[REDACTED_CREDIT_CARD]",
  )
  let input = "My secret token is secret_token and my credit card is 1234-5678-9012-3456. My email is user@example.com."
  let output = redactor.redact_text(input)
  inspect(
    output,
    content="My secret token is [REDACTED] and my credit card is [REDACTED_CREDIT_CARD]. My email is user@example.com.",
  )
}

///|
test "JsonPath" {
  @json.inspect(@redact.JsonPath::parse("$.user.password"), content=[
    "$", "user", "password",
  ])
  @json.inspect(@redact.JsonPath::parse("$.store.book[0].title"), content=[
    "$", "store", "book", 0, "title",
  ])
}
