# `MessageUnqueuedEvent`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L51)

```ts
type MessageUnqueuedEvent = {
  msg: "MessageUnqueued";
  message: { id: string };
};
```

MoonBit: [`event/event.mbt`](../../event/event.mbt#L55)

```mbt
MessageUnqueued(id~ : @uuid.Uuid)
```

Emitted when a previously queued message (see `QueuedMessage`) is removed
from the pending queue by the daemon. The UI uses `message.id` to remove the
corresponding entry from `Task.inputQueue`.

JSON encoding:

```jsonc
{
  "msg": "MessageUnqueued",
  "message": {
    "id": "queued-message-id"
  }
}
```
