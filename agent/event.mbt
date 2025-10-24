///|
/// Event type that occurs during agent conversation lifecycle.
pub enum Event {
  PreConversation
  PostConversation
  MessageAdded(@openai.ChatCompletionMessageParam)
  PreToolCall(@openai.ChatCompletionMessageToolCall)
  PostToolCall(
    @openai.ChatCompletionMessageToolCall,
    result~ : @tool.Result,
    rendered~ : String
  )
  TokenCounted(Int)
  ContextPruned(origin_token_count~ : Int, pruned_token_count~ : Int)
  RequestCompleted(
    usage~ : @openai.CompletionUsage?,
    message~ : @openai.ChatCompletionMessage
  )
}

///|
priv struct EventTarget {
  queue : @aqueue.Queue[Event]
  listeners : Array[async (Event) -> Unit]
}

///|
fn EventTarget::new() -> EventTarget {
  EventTarget::{ queue: @aqueue.Queue::new(), listeners: [] }
}

///|
fn EventTarget::emit(self : EventTarget, event : Event) -> Unit {
  self.queue.put(event)
}

///|
fn EventTarget::add_listener(
  self : EventTarget,
  f : async (Event) -> Unit,
) -> Unit {
  self.listeners.push(f)
}

///|
async fn EventTarget::start(self : EventTarget) -> Unit {
  while true {
    let event = self.queue.get()
    for listener in self.listeners {
      listener(event)
    }
  }
}
