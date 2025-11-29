///|
struct Pruner {
  token_counter : @token_counter.Counter
  safe_zone_tokens : Int
  event_target : @event.EventTarget
}

///|
pub struct ContextPruned {
  origin_token_count : Int
  pruned_token_count : Int
  pruned_index : Array[Int]?
  prune_goal_met : Bool?
}

///|
pub fn ContextPruned::new(
  origin_token_count~ : Int,
  pruned_token_count~ : Int,
  pruned_index? : Array[Int],
  prune_goal_met? : Bool,
) -> ContextPruned {
  ContextPruned::{
    origin_token_count,
    pruned_token_count,
    pruned_index,
    prune_goal_met,
  }
}

///|
pub impl ToJson for ContextPruned with to_json(self : ContextPruned) -> Json {
  let object : Map[String, Json] = {
    "msg": "ContextPruned",
    "origin_token_count": self.origin_token_count,
    "pruned_token_count": self.pruned_token_count,
  }
  if self.pruned_index is Some(pruned_index) {
    object["pruned_index"] = pruned_index.to_json()
  }
  if self.prune_goal_met is Some(prune_goal_met) {
    object["prune_goal_met"] = prune_goal_met.to_json()
  }
  Json::object(object)
}

///|
pub impl @event.Type for ContextPruned

///|
pub fn Pruner::new(
  safe_zone_tokens~ : Int,
  event_target? : @event.EventTarget = @event.default_target,
) -> Pruner raise {
  Pruner::{
    token_counter: @token_counter.Counter::new(event_target~),
    safe_zone_tokens,
    event_target,
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
  pruner.event_target.emit(
    ContextPruned::new(
      origin_token_count=tokens,
      pruned_token_count=pruned_tokens,
      pruned_index~,
      prune_goal_met~,
    ),
  )
}
