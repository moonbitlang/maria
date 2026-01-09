///|
/// The Compactor handles context compaction for long conversations.
///
/// It monitors token usage and triggers compaction when the conversation
/// exceeds a configurable threshold, summarizing the conversation history
/// to stay within model context limits.
pub struct Compactor {
  logger : @pino.Logger
  /// Token threshold that triggers auto-compaction
  auto_compact_token_limit : Int
}

///|
/// Creates a new Compactor with the specified configuration.
///
/// Parameters:
///
/// * `logger` : Logger instance for recording compaction events.
/// * `safe_zone_tokens` : The model's safe zone token limit. The auto-compact
///   threshold will be set to 90% of this value.
/// * `auto_compact_token_limit` : Optional override for the auto-compact
///   threshold. If not provided, defaults to 90% of `safe_zone_tokens`.
///
/// Returns a new `Compactor` instance.
pub fn Compactor::new(
  logger~ : @pino.Logger,
  safe_zone_tokens~ : Int,
  auto_compact_token_limit? : Int,
) -> Compactor {
  let limit = match auto_compact_token_limit {
    Some(limit) => limit
    None => safe_zone_tokens * 9 / 10
  }
  { logger, auto_compact_token_limit: limit }
}

///|
/// Checks if compaction should be triggered based on current token usage.
///
/// Parameters:
///
/// * `self` : The compactor instance.
/// * `current_tokens` : The current total token count of the conversation.
///
/// Returns `true` if the conversation should be compacted.
pub fn Compactor::should_compact(
  self : Compactor,
  current_tokens : Int,
) -> Bool {
  current_tokens >= self.auto_compact_token_limit
}

///|
/// Builds the prompt to send to the LLM for generating a compaction summary.
///
/// Parameters:
///
/// * `self` : The compactor instance.
/// * `messages` : The full conversation history to summarize.
///
/// Returns a string containing the summarization prompt with conversation
/// context.
pub fn Compactor::build_summarization_prompt(
  self : Compactor,
  messages : Array[@ai.Message],
) -> String {
  let _ = self
  let mut conversation = ""
  for message in messages {
    let role = match message {
      @ai.Message::User(_) => "User"
      @ai.Message::System(_) => "System"
      @ai.Message::Assistant(_, ..) => "Assistant"
      @ai.Message::Tool(_, ..) => "Tool"
    }
    conversation = "\{conversation}\n[\{role}]: \{message.content()}\n"
  }
  (
    $|\{SUMMARIZATION_PROMPT}
    $|
    $|---
    $|CONVERSATION TO SUMMARIZE:
    $|\{conversation}
  )
}
