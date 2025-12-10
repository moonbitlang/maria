# `PreToolCallEvent`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L133)

```ts
type ToolCallFunction = {
  name: string;
  arguments: string; // JSON string
};

type ToolCall = {
  id: string;
  function: ToolCallFunction;
};

export type PreToolCallEvent = {
  msg: "PreToolCall";
  tool_call: ToolCall;
};
```

MoonBit: [`event/event.mbt`](../../event/event.mbt#L62)

```mbt
PreToolCall(@ai.ToolCall)
```

Emitted right before a tool is executed. The UI:

- Parses `tool_call.function.arguments` as JSON to show the structured input
- Uses `tool_call.id` to later match the corresponding `PostToolCall` event

JSON encoding:

```jsonc
{
  "msg": "PreToolCall",
  "tool_call": {
    "id": "call_123",
    "type": "function",
    "function": {
      "name": "read_file",
      "arguments": "{ \"path\": \"README.md\" }"
    }
  },
  // helper fields used mainly for debugging / logs
  "name": "read_file",
  "args": { "path": "README.md" } // or a JSON‑encoded string on parse error
}
```
