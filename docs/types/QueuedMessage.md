# `QueuedMessage`

`QueuedMessage` is not part of the public API between the UI and daemon, but is
used both internally by the UI and daemon to model queued messages.

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L4)

```ts
export type QueuedMessage = {
  id: string;
  content: string;
};
```

MoonBit:

- `(@uuid.Uuid, Bool)` tuple in
  [`cmd/server/server.mbt`](../../cmd/server/server.mbt#L12) to represent queued
  message IDs

- [`MessageQueued`](../../event/event.mbt#L57) /
  [`MessageUnqueued`](../../event/event.mbt#L55) variants of `OutgoingEvent` in
  [`event/event.mbt`](../../event/event.mbt#L36) to signal queued message changes

- [`QueuedMessage`](../../agent/agent.mbt#L2) struct in
  [`agent/agent.mbt`](../../agent/agent.mbt) to represent queued messages for
  communication between server and agent.

  ```mbt
  pub struct QueuedMessage {
    id : @uuid.Uuid
    message : @ai.Message
    web_search : Bool
  }
  ```

JSON encoding: *not serialized directly*.

When the user sends messages while a task is still `"generating"`, the daemon
may choose to enqueue them instead of interrupting the current run. The UI
stores those as `QueuedMessage` entries in a per‑task queue and surfaces them
in the input panel.

The daemon notifies the UI that a queued message has been consumed via a
`MessageUnqueued` task event.
