///|
test "Compactor::new/default_threshold" {
  // When no auto_compact_token_limit is provided, it should default to 90% of safe_zone_tokens
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(logger~, safe_zone_tokens=100_000)
  // 90% of 100_000 = 90_000
  inspect(compactor.should_compact(89_999), content="false")
  inspect(compactor.should_compact(90_000), content="true")
  inspect(compactor.should_compact(90_001), content="true")
}

///|
test "Compactor::new/custom_threshold" {
  // When auto_compact_token_limit is provided, it should use that value
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(
    logger~,
    safe_zone_tokens=100_000,
    auto_compact_token_limit=50_000,
  )
  inspect(compactor.should_compact(49_999), content="false")
  inspect(compactor.should_compact(50_000), content="true")
}

///|
test "Compactor::should_compact/boundary" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(logger~, safe_zone_tokens=1000)
  // Threshold is 900 (90% of 1000)
  inspect(compactor.should_compact(0), content="false")
  inspect(compactor.should_compact(899), content="false")
  inspect(compactor.should_compact(900), content="true")
  inspect(compactor.should_compact(1000), content="true")
  inspect(compactor.should_compact(10_000), content="true")
}

///|
test "Compactor::build_summarization_prompt/empty_messages" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(logger~, safe_zone_tokens=100_000)
  let messages : Array[@ai.Message] = []
  let prompt = compactor.build_summarization_prompt(messages)
  // Use snapshot to verify the prompt structure
  inspect(
    prompt,
    content=(
      #|You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff summary for another LLM that will resume the task.
      #|
      #|Include:
      #|- Current progress and key decisions made
      #|- Important context, constraints, or user preferences
      #|- What remains to be done (clear next steps)
      #|- Any critical data, examples, or references needed to continue
      #|
      #|Be concise, structured, and focused on helping the next LLM seamlessly continue the work.
      #|
      #|---
      #|CONVERSATION TO SUMMARIZE:
      #|
    ),
  )
}

///|
test "Compactor::build_summarization_prompt/single_user_message" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(logger~, safe_zone_tokens=100_000)
  let messages = [@ai.user_message(content="Hello, world!")]
  let prompt = compactor.build_summarization_prompt(messages)
  // Verify the prompt contains the user message with proper formatting
  inspect(
    prompt,
    content=(
      #|You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff summary for another LLM that will resume the task.
      #|
      #|Include:
      #|- Current progress and key decisions made
      #|- Important context, constraints, or user preferences
      #|- What remains to be done (clear next steps)
      #|- Any critical data, examples, or references needed to continue
      #|
      #|Be concise, structured, and focused on helping the next LLM seamlessly continue the work.
      #|
      #|---
      #|CONVERSATION TO SUMMARIZE:
      #|
      #|[User]: Hello, world!
      #|
    ),
  )
}

///|
test "Compactor::build_summarization_prompt/multiple_message_types" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(logger~, safe_zone_tokens=100_000)
  let messages = [
    @ai.system_message(content="You are a helpful assistant."),
    @ai.user_message(content="What is 2+2?"),
    @ai.assistant_message(content="2+2 equals 4."),
    @ai.user_message(content="Thanks!"),
  ]
  let prompt = compactor.build_summarization_prompt(messages)
  inspect(
    prompt,
    content=(
      #|You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff summary for another LLM that will resume the task.
      #|
      #|Include:
      #|- Current progress and key decisions made
      #|- Important context, constraints, or user preferences
      #|- What remains to be done (clear next steps)
      #|- Any critical data, examples, or references needed to continue
      #|
      #|Be concise, structured, and focused on helping the next LLM seamlessly continue the work.
      #|
      #|---
      #|CONVERSATION TO SUMMARIZE:
      #|
      #|[System]: You are a helpful assistant.
      #|
      #|[User]: What is 2+2?
      #|
      #|[Assistant]: 2+2 equals 4.
      #|
      #|[User]: Thanks!
      #|
    ),
  )
}

///|
test "Compactor::build_summarization_prompt/with_tool_message" {
  let logger = @pino.logger("test", @pino.Transport::sink())
  let compactor = @compact.Compactor::new(logger~, safe_zone_tokens=100_000)
  let messages = [
    @ai.user_message(content="Read the file"),
    @ai.tool_message(content="File contents here", tool_call_id="call_123"),
  ]
  let prompt = compactor.build_summarization_prompt(messages)
  inspect(
    prompt,
    content=(
      #|You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff summary for another LLM that will resume the task.
      #|
      #|Include:
      #|- Current progress and key decisions made
      #|- Important context, constraints, or user preferences
      #|- What remains to be done (clear next steps)
      #|- Any critical data, examples, or references needed to continue
      #|
      #|Be concise, structured, and focused on helping the next LLM seamlessly continue the work.
      #|
      #|---
      #|CONVERSATION TO SUMMARIZE:
      #|
      #|[User]: Read the file
      #|
      #|[Tool]: File contents here
      #|
    ),
  )
}
