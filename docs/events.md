# Task Events

At the TypeScript level (UI side), a task event is defined as `TaskEvent` in
[`ui/core/src/lib/types.ts`](../ui/core/src/lib/types.ts#L27):

```ts
type TaskEventBase = { id: number };

export type TaskEvent = TaskEventBase &
  | RequestCompletedEvent
  | PreToolCallEvent
  | PostToolCallEvent
  | MessageAddedEvent
  | PostConversationEvent
  | MessageUnqueuedEvent
  | TodoUpdatedEvent;
```

MoonBit: [`event/event.mbt`](../event/event.mbt#L36)

```mbt
pub(all) enum OutgoingEvent {
  ModelLoaded(name~ : String, model~ : @model.Model)
  PreConversation
  PostConversation
  MessageAdded(@ai.Message)
  MessageUnqueued(id~ : @uuid.Uuid)
  MessageQueued(id~ : @uuid.Uuid, @ai.Message)
  ToolAdded(@tool.ToolDesc)
  PreToolCall(@ai.ToolCall)
  PostToolCall(@ai.ToolCall, result~ : Result[Json, Json], rendered~ : String)
  TokenCounted(Int)
  ContextPruned(origin_token_count~ : Int, pruned_token_count~ : Int)
  RequestCompleted(usage~ : @ai.Usage?, message~ : @ai.Message)
  ExternalEventReceived(ExternalEvent)
  Cancelled
  TodoUpdated(Json)
}
```

JSON encoding:

```jsonc
// All task events share a common "msg" discriminator and optional payload
// fields. The exact payload depends on the variant.
{
  "id": "550e8400-e29b-41d4-a716-446655440000", // randomly generated UUIDv4 per task
  "msg": "MessageAdded" | "RequestCompleted" | "PreToolCall" |
         "PostToolCall" | "PostConversation" | "MessageUnqueued" |
         "TodoUpdated",
  // ...variant‑specific fields...
}
```

The `id` is a randomly generated UUIDv4 per task and is used solely to avoid
re‑rendering the same event twice on the UI. See
[`cmd/server/server.mbt`](../cmd/server/server.mbt#L61)

Below are the individual variants and their semantics.

- [`MessageAddedEvent`](events/MessageAdded.md)
- [`RequestCompletedEvent`](events/RequestCompleted.md)
- [`PostConversationEvent`](events/PostConversation.md)
- [`PostToolCallEvent`](events/PostToolCall.md)
- [`PreToolCallEvent`](events/PreToolCall.md)
- [`MessageUnqueuedEvent`](events/MessageUnqueued.md)
- [`TodoUpdatedEvent`](events/TodoUpdated.md)
