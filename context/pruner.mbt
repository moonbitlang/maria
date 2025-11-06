///|
struct Pruner {
  token_counter : @token.Counter
  safe_zone_tokens : Int
}

///|
pub fn Pruner::new(safe_zone_tokens~ : Int) -> Pruner raise {
  Pruner::{ token_counter: @token.Counter::new(), safe_zone_tokens }
}

///|
pub fn Pruner::prune_messages(
  pruner : Pruner,
  messages : Array[@openai.ChatCompletionMessageParam],
  tools? : Array[@openai.ChatCompletionToolParam] = [],
) -> Unit raise {
  let tokens = pruner.token_counter.count_param(
    @openai.chat_completion(messages~, model="gpt-4o", tools~),
  )
  if tokens <= pruner.safe_zone_tokens {
    return
  }
  for i in 0..<messages.length() {
    let message = messages[i]
    match message {
      Tool(tool) => {
        messages[i] = @openai.tool_message(
          content="[Cleared: tool output. If you want to see the output, you can use the tool again.]",
          tool_call_id=tool.tool_call_id,
        )
        let tokens = pruner.token_counter.count_param(
          @openai.chat_completion(messages~, model="gpt-4o", tools~),
        )
        if tokens <= pruner.safe_zone_tokens {
          return
        }
      }
      _ => ()
    }
  }
}
