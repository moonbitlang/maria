# `RequestCompletedEvent`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L70)

```ts
export type RequestCompletedEvent = {
  msg: "RequestCompleted";
  message: {
    content: string;       // final assistant text content
    role: "assistant";
    tool_calls: ToolCall[]; // tool calls (if any) used in this response
  };
};
```

MoonBit: [`event/event.mbt`](../../event/event.mbt#L94)

```mbt
RequestCompleted(usage~ : @ai.Usage?, message~ : @ai.Message)
```

Emitted when a chat completion finishes. The UI renders `message.content` as
the assistant bubble in the conversation view.

JSON encoding:

```jsonc
{
  "msg": "RequestCompleted",
  "usage": null | [
    {
      // OpenAI‑style token usage object (see @ai.Usage::to_openai)
    }
  ],
  "message": {
    "role": "assistant",
    "content": [
      { "type": "text", "text": "..." }
    ],
    "tool_calls": [
      {
        "id": "call_123",
        "type": "function",
        "function": { "name": "read_file", "arguments": "{...}" }
      }
    ]
  }
}
```
