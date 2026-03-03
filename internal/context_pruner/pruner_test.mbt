///|
/// Helper to create a conversation with events for testing
async fn create_test_conversation(
  mock : @mock.Context,
  events : Array[@event.EventDesc],
) -> @conversation.Conversation {
  let manager = @conversation.Manager::new(
    uuid=mock.uuid,
    clock=mock.clock,
    home=mock.cwd.path(),
  )
  let conversation = manager.new_conversation(
    name="Test Conversation",
    cwd=mock.cwd.path(),
  )
  let event_target = @event.EventTarget::new(uuid=mock.uuid)
  event_target.add_listener(event => conversation.add_event(event))
  for desc in events {
    event_target.emit(desc)
  }
  event_target.flush()
  conversation
}

///|
async test "calculate_pruning/no_pruning_needed" (t : @test.Test) {
  @mock.run(t, mock => {
    let conversation = create_test_conversation(mock, [
      UserMessage("Hello"),
      AssistantMessage(usage=None, "Hi there!", tool_calls=[]),
    ])
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=10000,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)
    // Should not prune anything since we're well within budget
    json_inspect(result.pruned_ids.length(), content=0)
    json_inspect(
      result.origin_token_count == result.pruned_token_count,
      content=true,
    )
  })
}

///|
async test "calculate_pruning/prunes_tool_output" (t : @test.Test) {
  @mock.run(t, mock => {
    let large_output = "x".repeat(10000)
    let conversation = create_test_conversation(mock, [
      UserMessage("Run command"),
      AssistantMessage(usage=None, "Running", tool_calls=[
        @ai.tool_call(id="call_1", name="execute", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_1", name="execute", arguments="{}"),
        result=Ok(Json::string(large_output)),
        rendered=large_output,
      ),
    ])
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)
    // Should mark the PostToolCall event for pruning
    json_inspect(result.pruned_ids.length(), content=1)
    json_inspect(
      result.pruned_token_count < result.origin_token_count,
      content=true,
    )
  })
}

///|
async test "calculate_pruning/multiple_tools_oldest_first" (t : @test.Test) {
  @mock.run(t, mock => {
    let output1 = "output1".repeat(500)
    let output2 = "output2".repeat(500)
    let output3 = "output3".repeat(500)
    let conversation = create_test_conversation(mock, [
      UserMessage("Test"),
      AssistantMessage(usage=None, "Calling tool 1", tool_calls=[
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
        result=Ok(Json::string(output1)),
        rendered=output1,
      ),
      AssistantMessage(usage=None, "Calling tool 2", tool_calls=[
        @ai.tool_call(id="call_2", name="tool", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_2", name="tool", arguments="{}"),
        result=Ok(Json::string(output2)),
        rendered=output2,
      ),
      AssistantMessage(usage=None, "Calling tool 3", tool_calls=[
        @ai.tool_call(id="call_3", name="tool", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_3", name="tool", arguments="{}"),
        result=Ok(Json::string(output3)),
        rendered=output3,
      ),
    ])
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=200,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)
    // Should prune multiple tool outputs, oldest first
    json_inspect(result.pruned_ids.length() > 0, content=true)
    json_inspect(
      result.pruned_token_count < result.origin_token_count,
      content=true,
    )
    json_inspect(result.pruned_token_count <= 200, content=true)
  })
}

///|
async test "calculate_pruning/respects_already_pruned" (t : @test.Test) {
  @mock.run(t, mock => {
    let output = "x".repeat(5000)
    // First, create conversation with a PostToolCall
    let manager = @conversation.Manager::new(
      uuid=mock.uuid,
      clock=mock.clock,
      home=mock.cwd.path(),
    )
    let conversation = manager.new_conversation(
      name="Test",
      cwd=mock.cwd.path(),
    )
    let event_target = @event.EventTarget::new(uuid=mock.uuid)
    event_target.add_listener(event => conversation.add_event(event))
    event_target.emit(UserMessage("Test"))
    event_target.emit(
      AssistantMessage(usage=None, "Running", tool_calls=[
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
      ]),
    )
    event_target.emit(
      PostToolCall(
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
        result=Ok(Json::string(output)),
        rendered=output,
      ),
    )
    event_target.flush()

    // Get the PostToolCall event ID
    let post_tool_call_id = conversation.events()[2].id

    // Now add a Pruned event for that PostToolCall
    event_target.emit(Pruned(id=post_tool_call_id))
    event_target.flush()
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)

    // Should not re-prune already pruned events
    json_inspect(result.pruned_ids.length(), content=0)
  })
}

///|
async test "calculate_pruning/no_tool_messages" (t : @test.Test) {
  @mock.run(t, mock => {
    let conversation = create_test_conversation(mock, [
      UserMessage("Hello"),
      AssistantMessage(usage=None, "Hi there!", tool_calls=[]),
      UserMessage("How are you?"),
      AssistantMessage(usage=None, "I'm fine, thanks!", tool_calls=[]),
    ])
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=10, // Very low budget
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)
    // Should not prune anything since there are no PostToolCall events
    json_inspect(result.pruned_ids.length(), content=0)
  })
}

///|
async test "calculate_pruning/empty_conversation" (t : @test.Test) {
  @mock.run(t, mock => {
    let conversation = create_test_conversation(mock, [])
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)
    // Should handle empty conversation gracefully
    json_inspect(result.pruned_ids.length(), content=0)
    json_inspect(result.origin_token_count, content=7) // Just system overhead
  })
}

///|
async test "calculate_pruning/stops_at_budget" (t : @test.Test) {
  @mock.run(t, mock => {
    let small_output = "x".repeat(100)
    let conversation = create_test_conversation(mock, [
      UserMessage("Test"),
      AssistantMessage(usage=None, "Tool 1", tool_calls=[
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
        result=Ok(Json::string(small_output)),
        rendered=small_output,
      ),
      AssistantMessage(usage=None, "Tool 2", tool_calls=[
        @ai.tool_call(id="call_2", name="tool", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_2", name="tool", arguments="{}"),
        result=Ok(Json::string(small_output)),
        rendered=small_output,
      ),
    ])
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation)
    // Should stop pruning once budget is met
    json_inspect(result.pruned_token_count <= 100, content=true)
  })
}

///|
async test "calculate_pruning/with_tools_parameter" (t : @test.Test) {
  @mock.run(t, mock => {
    let output = "x".repeat(5000)
    let conversation = create_test_conversation(mock, [
      UserMessage("Test"),
      AssistantMessage(usage=None, "Running", tool_calls=[
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
      ]),
      PostToolCall(
        @ai.tool_call(id="call_1", name="tool", arguments="{}"),
        result=Ok(Json::string(output)),
        rendered=output,
      ),
    ])
    let tools = [
      @openai.tool(name="test_tool", description="A test tool", parameters={
        "type": "object",
        "properties": {},
      }),
    ]
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    let result = pruner.calculate_pruning(conversation, tools~)
    // Should count tool overhead in token calculation
    json_inspect(result.pruned_ids.length() > 0, content=true)
  })
}

// ============================================================================
// Legacy tests for prune_messages (backward compatibility)
// ============================================================================

///|
async test "prune_messages/basic" (t : @test.Test) {
  let messages = [
    @openai.user_message(content="Hello"),
    @openai.assistant_message(content="Hi!"),
    @openai.user_message(content="What's the weather?"),
  ]
  @mock.run(t, mock => {
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    pruner.prune_messages(messages)
    // Should not modify anything since there are no tool messages
    json_inspect(messages.length(), content=3)
  })
}

///|
async test "prune_messages/large_tool_output" (t : @test.Test) {
  let messages = [
    @openai.user_message(content="Run command"),
    @openai.assistant_message(content="Running", tool_calls=[
      @openai.tool_call(id="call_1", name="execute", arguments="{}"),
    ]),
    @openai.tool_message(tool_call_id="call_1", content="x".repeat(10000)),
  ]
  @mock.run(t, mock => {
    let counter = @token_counter.Counter::new(logger=mock.logger)
    let tokens_before = counter.count_param(messages~)
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    pruner.prune_messages(messages)
    let tokens_after = counter.count_param(messages~)
    // Tool output should be replaced with placeholder
    json_inspect(tokens_after < tokens_before, content=true)
  })
}

///|
async test "prune_messages/empty" (t : @test.Test) {
  let messages : Array[@openai.ChatCompletionMessageParam] = []
  @mock.run(t, mock => {
    let pruner = @context_pruner.Pruner::new(
      safe_zone_tokens=100,
      logger=mock.logger,
    )
    pruner.prune_messages(messages)
    // Should handle empty array gracefully
    json_inspect(messages.length(), content=0)
  })
}
