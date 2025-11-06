///|
test "redact_string" {
  let redactor = @redact.Redactor::new()
  redactor.add_string("secret", "[REDACTED]")
  let source = "This is a secret message containing secret information."
  let redacted = redactor.redact_string(source)
  inspect(
    redacted,
    content="This is a [REDACTED] message containing [REDACTED] information.",
  )
}

///|
test "redact_string with regexp" {
  let redactor = @redact.Redactor::new()
  let pattern = @regexp.compile(
    (
      #|\b\d{4}-\d{2}-\d{2}\b
    ),
  )
  @json.inspect(pattern.execute("2024-01-15").get(0), content=["2024-01-15"])
  redactor.add_regexp(pattern, "[DATE]")
  let source = "The events are scheduled on 2024-01-15 and 2024-02-20."
  let redacted = redactor.redact_string(source)
  inspect(redacted, content="The events are scheduled on [DATE] and [DATE].")
}
