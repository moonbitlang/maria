///|
pub struct PreToolCall {
  tool_call : @openai.ChatCompletionMessageToolCall
}

///|
trait Event {
  emit(events : Events, self : Self) -> Unit
  add_listener(events : Events, f : async (Self) -> Unit) -> Unit noraise
}

///|
pub impl Event for PreToolCall with emit(events : Events, self : PreToolCall) -> Unit {
  events.pre_tool_call.emit(self)
}

///|
pub impl Event for PreToolCall with add_listener(
  events : Events,
  f : async (PreToolCall) -> Unit,
) -> Unit noraise {
  events.pre_tool_call.add_listener(f)
}

///|
pub fn pre_tool_call(
  tool_call~ : @openai.ChatCompletionMessageToolCall,
) -> PreToolCall {
  PreToolCall::{ tool_call, }
}

///|
pub struct TokenCounted {
  origin_token_count : Int
  pruned_token_count : Int
}

///|
pub impl Event for TokenCounted with emit(events : Events, self : TokenCounted) -> Unit {
  events.token_counted.emit(self)
}

///|
pub impl Event for TokenCounted with add_listener(
  events : Events,
  f : async (TokenCounted) -> Unit,
) -> Unit noraise {
  events.token_counted.add_listener(f)
}

///|
pub fn token_counted(
  origin_token_count~ : Int,
  pruned_token_count~ : Int,
) -> TokenCounted {
  TokenCounted::{ origin_token_count, pruned_token_count }
}

///|
pub struct RequestCompleted {
  usage : @openai.CompletionUsage?
  message : @openai.ChatCompletionMessage
}

///|
pub impl Event for RequestCompleted with emit(
  events : Events,
  self : RequestCompleted,
) -> Unit {
  events.request_completed.emit(self)
}

///|
pub impl Event for RequestCompleted with add_listener(
  events : Events,
  f : async (RequestCompleted) -> Unit,
) -> Unit noraise {
  events.request_completed.add_listener(f)
}

///|
pub fn request_completed(
  usage? : @openai.CompletionUsage,
  message~ : @openai.ChatCompletionMessage,
) -> RequestCompleted {
  RequestCompleted::{ usage, message }
}

///|
struct Events {
  pre_tool_call : @event.Target[PreToolCall]
  post_tool_call : @event.Target[PostToolCall]
  token_counted : @event.Target[TokenCounted]
  request_completed : @event.Target[RequestCompleted]
  conversation_start : @event.Target[ConversationStart]
  conversation_end : @event.Target[ConversationEnd]
}

///|
pub fn new() -> Events {
  Events::{
    pre_tool_call: @event.Target::new(),
    post_tool_call: @event.Target::new(),
    token_counted: @event.Target::new(),
    request_completed: @event.Target::new(),
    conversation_start: @event.Target::new(),
    conversation_end: @event.Target::new(),
  }
}

///|
pub fn[T : Event] Events::emit(self : Events, event : T) -> Unit {
  Event::emit(self, event)
}

///|
pub fn[T : Event] Events::add_listener(
  self : Events,
  f : async (T) -> Unit,
) -> Unit noraise {
  Event::add_listener(self, f)
}

///|
pub async fn Events::start(self : Events) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(() => self.pre_tool_call.start())
    group.spawn_bg(() => self.token_counted.start())
    group.spawn_bg(() => self.request_completed.start())
    group.spawn_bg(() => self.post_tool_call.start())
    group.spawn_bg(() => self.conversation_start.start())
    group.spawn_bg(() => self.conversation_end.start())
  })
}

///|
pub struct PostToolCall {
  tool_call : @openai.ChatCompletionMessageToolCall
  result : @tool.Result
  rendered : String
}

///|
pub impl Event for PostToolCall with emit(events : Events, self : PostToolCall) -> Unit {
  events.post_tool_call.emit(self)
}

///|
pub impl Event for PostToolCall with add_listener(
  events : Events,
  f : async (PostToolCall) -> Unit,
) -> Unit noraise {
  events.post_tool_call.add_listener(f)
}

///|
pub fn post_tool_call(
  tool_call~ : @openai.ChatCompletionMessageToolCall,
  result~ : @tool.Result,
  rendered~ : String,
) -> PostToolCall {
  PostToolCall::{ tool_call, result, rendered }
}

///|
struct ConversationStart {}

///|
pub impl Event for ConversationStart with emit(
  events : Events,
  self : ConversationStart,
) -> Unit {
  events.conversation_start.emit(self)
}

///|
pub impl Event for ConversationStart with add_listener(
  events : Events,
  f : async (ConversationStart) -> Unit,
) -> Unit noraise {
  events.conversation_start.add_listener(f)
}

///|
pub fn conversation_start() -> ConversationStart {
  ConversationStart::{  }
}

///|
struct ConversationEnd {}

///|
pub impl Event for ConversationEnd with emit(
  events : Events,
  self : ConversationEnd,
) -> Unit {
  events.conversation_end.emit(self)
}

///|
pub impl Event for ConversationEnd with add_listener(
  events : Events,
  f : async (ConversationEnd) -> Unit,
) -> Unit noraise {
  events.conversation_end.add_listener(f)
}

///|
pub fn conversation_end() -> ConversationEnd {
  ConversationEnd::{  }
}

///|
pub fn Events::close(self : Events) -> Unit {
  self.pre_tool_call.close()
  self.post_tool_call.close()
  self.token_counted.close()
  self.request_completed.close()
  self.conversation_start.close()
  self.conversation_end.close()
}
