# `MessageAddedEvent`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L182)

```ts
type MessageContentPart = { text: string };

type MessageBase = {
  content: MessageContentPart[] | string;
};

type SystemMessage   = { role: "system" };
type UserMessage     = { role: "user" };
export type AssistantMessage = { role: "assistant"; tool_calls: ToolCall[] };
export type ToolMessage      = { role: "tool"; tool_call_id: string };

export type MessageAddedEvent = {
  msg: "MessageAdded";
  message: MessageBase &
    (SystemMessage | UserMessage | AssistantMessage | ToolMessage);
};
```

MoonBit: [`event/event.mbt`](../../event/event.mbt#L53)

```mbt
MessageAdded(@ai.Message)
```

This is emitted whenever a new message is appended to the conversation
history. The UI currently:

- Ignores `system`, `assistant`, and `tool` messages when rendering events,
  because they are better visualized via `RequestCompleted` and
  `PostToolCall`.
- Renders `user` messages as chat bubbles in the conversation timeline.

JSON encoding:

```jsonc
{
  "msg": "MessageAdded",
  "message": {
    "role": "user" | "system" | "assistant" | "tool",
    "content": [
      { "type": "text", "text": "..." }
    ],
    // for assistant / tool messages only
    "tool_calls": [ /* optional tool calls, OpenAI‑style */ ],
    "tool_call_id": "call_123" // for role === "tool"
  }
}
```
