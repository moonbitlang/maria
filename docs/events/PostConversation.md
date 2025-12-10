# `PostConversationEvent`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L56)

```ts
type PostConversationEvent = {
  msg: "PostConversation";
};
```

MoonBit: [`event/event.mbt`](../../event/event.mbt#L42)

```mbt
PostConversation
```

Signals that the daemon has finished processing a conversation. As of today
the core UI does not render this event specially, but it is part of the
`TaskEvent` union for future use.

JSON encoding:

```jsonc
{
  "msg": "PostConversation"
}
```
