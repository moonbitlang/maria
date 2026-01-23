///|
test "header" {
  let header = @httpx.Header::new()
  header.set("Content-Type", "application/json")
  header.add("Set-Cookie", "sessionid=abc123")
  header.add("Set-Cookie", "theme=dark")
  inspect(
    header,
    content=(
      #|{"Content-Type": "application/json", "Set-Cookie": "sessionid=abc123, theme=dark"}
    ),
  )
  json_inspect(header, content={
    "Content-Type": "application/json",
    "Set-Cookie": "sessionid=abc123, theme=dark",
  })
}
