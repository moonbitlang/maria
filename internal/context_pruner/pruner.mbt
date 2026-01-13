///|
struct Pruner {
  logger : @pino.Logger
  token_counter : @token_counter.Counter
  safe_zone_tokens : Int
}

///|
/// Result of pruning operation
pub struct PruneResult {
  /// Event IDs that should be pruned
  pruned_ids : Array[@uuid.Uuid]
  /// Original token count before pruning
  origin_token_count : Int
  /// Token count after pruning
  pruned_token_count : Int
}

///|
pub fn Pruner::new(
  safe_zone_tokens~ : Int,
  logger~ : @pino.Logger,
) -> Pruner raise {
  Pruner::{
    logger,
    token_counter: @token_counter.Counter::new(logger~),
    safe_zone_tokens,
  }
}

///|
const ClearedToolOutputPlaceholder : String = "[Cleared: tool output. If you want to see the output, you can use the tool again.]"

///|
/// Prunes in-memory chat context until it fits within the configured safe-zone token budget.
///
/// The pruner only redacts tool response messages because they typically contain the
/// largest payloads and can be regenerated on demand. Tool messages are replaced with a
/// short placeholder while preserving the original tool call id so that downstream state
/// remains consistent.
///
/// Parameters:
///
/// * `pruner`: Maintains logging and token counting utilities.
/// * `messages`: Mutable conversation history that will be truncated in place.
/// * `tools`: Tool descriptors needed when estimating token counts.
///
/// The function recalculates the token usage after each redaction, logging the reduction,
/// and stops once the budget is respected or no more tool messages are available.
pub async fn Pruner::prune_messages(
  pruner : Pruner,
  messages : Array[@openai.ChatCompletionMessageParam],
  tools? : Array[@openai.ChatCompletionToolParam] = [],
) -> Unit {
  let tokens = pruner.token_counter.count_param(messages~, tools~)
  if tokens <= pruner.safe_zone_tokens {
    return
  }
  let mut pruned_tokens = tokens // current state
  let pruned_index = []
  let prune_goal_met = for i, message in messages {
    match message {
      Tool(tool) => {
        if tool.content is [Text({ text: ClearedToolOutputPlaceholder, .. })] {
          // Already cleared, skip
          continue
        }
        messages[i] = @openai.tool_message(
          content=ClearedToolOutputPlaceholder,
          tool_call_id=tool.tool_call_id,
        )
        pruned_index.push(i)
        // TODO: this is O(n^2), optimize by tracking deltas
        pruned_tokens = pruner.token_counter.count_param(messages~, tools~)
        if pruned_tokens <= pruner.safe_zone_tokens {
          break true
        }
      }
      _ => ()
    }
  } else {
    false
  }
  pruner.logger.info("ContextPruned", data={
    "origin_token_count": tokens,
    "pruned_token_count": pruned_tokens,
    "pruned_index": pruned_index,
    "pruned_goal_met": prune_goal_met,
  })
}

///|
/// Determines which PostToolCall events should be pruned to fit within budget.
///
/// This method does NOT modify the conversation - it returns the IDs to prune.
/// The caller is responsible for emitting Pruned events.
///
/// Parameters:
///
/// * `conversation` : The conversation to analyze
/// * `tools` : Tool descriptors for token counting
///
/// Returns a PruneResult containing:
///
/// * `pruned_ids`: Array of event IDs to prune (oldest first)
/// * `origin_token_count`: Token count before pruning
/// * `pruned_token_count`: Token count after pruning
pub async fn Pruner::calculate_pruning(
  pruner : Pruner,
  conversation : @conversation.Conversation,
  tools? : Array[@openai.ChatCompletionToolParam] = [],
) -> PruneResult {
  // Build set of already-pruned IDs
  let already_pruned : Set[@uuid.Uuid] = Set::new()
  for e in conversation.events() {
    match e.desc {
      Pruned(id~) => already_pruned.add(id)
      _ => ()
    }
  }

  // Count current tokens
  let messages = conversation.messages(include_system=true)
  let openai_messages = messages.map(fn(msg) { msg.to_openai() })
  let origin_token_count = pruner.token_counter.count_param(
    messages=openai_messages,
    tools~,
  )
  if origin_token_count <= pruner.safe_zone_tokens {
    return {
      pruned_ids: [],
      origin_token_count,
      pruned_token_count: origin_token_count,
    }
  }

  // Collect prunable PostToolCall events (oldest first, not already pruned)
  // Each entry: (event_id, tool_call_id, rendered_content)
  let prunables : Array[(@uuid.Uuid, String, String)] = []
  for e in conversation.events() {
    if already_pruned.contains(e.id) {
      continue
    }
    match e.desc {
      PostToolCall(tc, rendered~, ..) => prunables.push((e.id, tc.id, rendered))
      _ => ()
    }
  }

  // Greedily prune oldest until within budget
  // We simulate the effect by building a modified message list
  let pruned_ids : Array[@uuid.Uuid] = []
  let mut current_tokens = origin_token_count
  for entry in prunables {
    let (event_id, tool_call_id, rendered) = entry
    if current_tokens <= pruner.safe_zone_tokens {
      break
    }
    // Estimate token savings from pruning this event
    let original_msg = @ai.tool_message(tool_call_id~, content=rendered)
    let pruned_msg = @ai.tool_message(
      tool_call_id~,
      content=ClearedToolOutputPlaceholder,
    )
    let original_tokens = pruner.token_counter.count_message(
      original_msg.to_openai(),
    )
    let pruned_msg_tokens = pruner.token_counter.count_message(
      pruned_msg.to_openai(),
    )
    let savings = original_tokens - pruned_msg_tokens
    pruned_ids.push(event_id)
    current_tokens -= savings
  }
  { pruned_ids, origin_token_count, pruned_token_count: current_tokens }
}
