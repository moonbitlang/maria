# `Message`

Conversation messages are modeled slightly differently in the UI and daemon,
but both sides agree on an OpenAI‑style JSON shape at the HTTP / SSE
boundaries.

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L156)

```ts
type MessageContentPart = { text: string };

type MessageBase = {
  content: MessageContentPart[] | string;
};

type SystemMessage = {
  role: "system";
};

type UserMessage = {
  role: "user";
};

export type AssistantMessage = {
  role: "assistant";
  tool_calls: ToolCall[];
};

export type ToolMessage = {
  role: "tool";
  tool_call_id: string;
};

export type MessageAddedEvent = {
  msg: "MessageAdded";
  message: MessageBase &
    (SystemMessage | UserMessage | AssistantMessage | ToolMessage);
};

export type RequestCompletedEvent = {
  msg: "RequestCompleted";
  message: {
    content: string;
    role: "assistant";
    tool_calls: ToolCall[];
  };
};
```

On the UI side:

- `MessageAddedEvent` is emitted for each message appended to the
  conversation. The UI currently renders only `role: "user"` entries as chat
  bubbles; `assistant` and `tool` messages are better represented via
  `RequestCompletedEvent` and `PostToolCallEvent`.
- `RequestCompletedEvent.message` represents the final assistant turn for a
  completion, with `content` already flattened to a single string and
  `tool_calls` mirroring the underlying OpenAI tool call array.

MoonBit (`ai` package): [`ai/message.mbt`](../../ai/message.mbt),
[`ai/convert.mbt`](../../ai/convert.mbt)

```mbt
pub enum Message {
  User(String)
  System(String)
  Assistant(String, tool_calls~ : Array[ToolCall])
  Tool(String, tool_call_id~ : String)
}

pub struct ToolCall {
  id : String
  name : String
  arguments : String?
}

pub struct Usage {
  input_tokens : Int
  output_tokens : Int
  total_tokens : Int
  cache_read_tokens : Int?
}
```

The daemon uses `@ai.Message` as its canonical in‑memory representation of
conversation turns. Helper constructors like `user_message`, `system_message`,
`assistant_message`, and `tool_message` are used throughout the agent to build
messages, for example in `Agent::add_message` and `Agent::queue_message`
[`agent/agent.mbt`](../../agent/agent.mbt).

There is a dedicated conversion layer between `@ai.Message` and OpenAI‑style
wire types defined in the `internal/openai` package:

MoonBit (`ai` ↔ `internal/openai` conversions):

- `Message::to_openai(self : Message) -> @openai.ChatCompletionMessageParam`
- `Message::from_openai(param : @openai.ChatCompletionMessageParam) -> Message`
- `Message::from_openai_response(msg : @openai.ChatCompletionMessage) -> Message`
- `ToolCall::to_openai(self : ToolCall) -> @openai.ChatCompletionMessageToolCall`
- `ToolCall::from_openai_tool_call(tc : @openai.ChatCompletionMessageToolCall) -> ToolCall`
- `Usage::to_openai(self : Usage) -> @openai.CompletionUsage`
- `Usage::from_openai(u : @openai.CompletionUsage) -> Usage`

The `internal/openai` package
([`internal/openai/types.mbt`](../../internal/openai/types.mbt),
[`internal/openai/json.mbt`](../../internal/openai/json.mbt),
[`internal/openai/ai.mbt`](../../internal/openai/ai.mbt)) defines the full set of
OpenAI‑compatible request/response types (`ChatCompletionMessageParam`,
`ChatCompletionMessage`, `Request`, `ChatCompletion`, `CompletionUsage`, etc.)
and their JSON encoders/decoders. These types are used whenever the daemon
actually serializes or parses JSON for the upstream model APIs.

JSON encoding

At the UI boundary, conversation messages always use OpenAI chat-completion
shapes. The UI only relies on a subset of the full schema:

```jsonc
// System message
{
  "role": "system",
  "content": "You are a helpful assistant."
}

// User message
{
  "role": "user",
  "content": "Write a unit test for foo()"
}

// Assistant message without tools
{
  "role": "assistant",
  "content": "Here is a test you can use..."
}

// Assistant message with tool calls
{
  "role": "assistant",
  "content": [
    { "type": "text", "text": "Let me inspect the file first." }
  ],
  "tool_calls": [
    {
      "id": "call_123",
      "type": "function",
      "function": {
        "name": "read_file",
        "arguments": "{ \"path\": \"README.md\" }"
      }
    }
  ]
}

// Tool message (tool output fed back to the model)
{
  "role": "tool",
  "content": "...tool output rendered as text...",
  "tool_call_id": "call_123"
}
```

Notes:

- `content` may be either a plain string or an array of text parts
  (`[{ "type": "text", "text": string }]`). The UI normalizes this into
  `MessageContentPart[] | string`.
- `tool_calls` only appears on assistant messages; the UI surfaces it on
  `AssistantMessage.tool_calls` and in `RequestCompletedEvent.message`.
- `tool_call_id` only appears on tool messages; the UI maps it to
  `ToolMessage.tool_call_id`.

These message objects are then wrapped by higher-level event envelopes that
the UI listens to over SSE:

```jsonc
// From /task/:id/events (SSE "maria" event)
{
  "msg": "MessageAdded",
  "message": { /* one of the message shapes above */ }
}

{
  "msg": "RequestCompleted",
  "usage": null | [ { /* token usage */ } ],
  "message": { /* assistant message shape with tool_calls */ }
}
```

Queued messages surfaced via
`maria.queued_messages.synchronized`/`GET /v1/queued_messages` follow the same
pattern, but wrapped with an `id` field:

```jsonc
{
  "id": "queued-message-id",
  "message": { /* one of the message shapes above */ }
}
```

All other message-related JSON that the UI sees (HTTP `POST /task` initial
message, `POST /task/:id/message`, SSE task events) is a direct reuse of these
shapes.
