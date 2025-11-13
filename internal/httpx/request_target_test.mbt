///|
test "OriginFormRequestTarget::parse" {
  let request_target = @httpx.OriginFormRequestTarget::parse(
    "/path/to/resource?key1=value1&key2=value2",
  )
  @json.inspect(request_target, content={
    "segments": ["", "path", "to"],
    "query": "key1=value1&key2=value2",
  })
}
