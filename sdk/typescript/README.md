# Maria TypeScript SDK

TypeScript bindings for the Maria agent executable.

## Installation

```bash
npm install maria
```

## Usage

```typescript
import { Maria } from "maria";

async function main() {
    const maria = new Maria();

    for await (const event of maria.start("Hello, Maria!")) {
        if (event.method === "maria.agent.request_completed") {
            const content = event.params.message.content;
            if (content) {
                console.log(content);
            }
        } else if (event.method === "maria.agent.post_tool_call") {
            const toolCall = event.params.tool_call;

            if (toolCall.type === "function" && toolCall.function) {
                console.log(`Tool: ${toolCall.function.name}`);
                console.log(`Args: ${toolCall.function.arguments}`);
            }

            console.log(`Output: ${event.params.text}`);
        }
    }
}

main().catch(console.error);
```

## API

### `Maria`

The main class for interacting with Maria.

#### `start(prompt: string): AsyncGenerator<Notification>`

Starts Maria with the given prompt and returns an async generator that yields
notifications.

### Events

#### `RequestCompleted`

Emitted when Maria completes a request.

```typescript
interface RequestCompleted {
    method: "maria.agent.request_completed";
    params: {
        usage: CompletionUsage;
        message: ChatCompletionMessage;
    };
}
```

#### `PostToolCall`

Emitted when Maria executes a tool call.

```typescript
interface PostToolCall {
    method: "maria.agent.post_tool_call";
    params: {
        tool_call: ChatCompletionMessageToolCall;
        value: unknown;
        text: string;
    };
}
```

## Requirements

- Node.js >= 18.0.0
- The Maria executable must be available in the package's `bin/` directory

## Platform Support

The SDK automatically detects your platform and looks for the appropriate Maria
executable:

- `darwin-arm64.exe` for macOS on Apple Silicon
- `darwin-x86_64.exe` for macOS on Intel
- `linux-x86_64.exe` for Linux on x64
- `linux-arm64.exe` for Linux on ARM64
- `win32-x86_64.exe` for Windows on x64

## License

Apache-2.0
