///|
test "content" {
  @json.inspect(
    @ai.user_message(content="Hello, world!").content(),
    content="Hello, world!",
  )
  @json.inspect(
    @ai.system_message(content="System message").content(),
    content="System message",
  )
  @json.inspect(
    @ai.assistant_message(content="Assistant message", tool_calls=[
      @ai.tool_call(
        id="tc_1",
        name="get_info",
        arguments="{\"param\": \"value\"}",
      ),
    ]).content(),
    content="Assistant message",
  )
  @json.inspect(
    @ai.tool_message(content="Tool output", tool_call_id="tc_1").content(),
    content="Tool output",
  )
}

///|
test "usage" {
  let usage = @ai.usage(
    input_tokens=200,
    output_tokens=400,
    cache_read_tokens=150,
  )
  @json.inspect(usage.input_tokens, content=200)
  @json.inspect(usage.output_tokens, content=400)
  @json.inspect(usage.total_tokens, content=600)
  @json.inspect(usage.cache_read_tokens, content=[150])
}

///|
test "tool_call" {
  let tc = @ai.tool_call(
    id="tc_123",
    name="fetch_data",
    arguments="{\"query\": \"latest news\"}",
  )
  @json.inspect(tc.id, content="tc_123")
  @json.inspect(tc.name, content="fetch_data")
  @json.inspect(tc.arguments, content=["{\"query\": \"latest news\"}"])
  let tc_wo_args = @ai.tool_call(id="tc_456", name="get_status")
  @json.inspect(tc_wo_args.id, content="tc_456")
  @json.inspect(tc_wo_args.name, content="get_status")
  @json.inspect(tc_wo_args.arguments, content=null)
}
