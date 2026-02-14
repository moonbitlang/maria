# Event Package

The `event` package provides a comprehensive event system for the Maria AI agent framework. It implements an event-driven architecture that enables components to communicate through well-defined events during the agent's conversation lifecycle.

## Architecture Overview

The package consists of three main components:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Agent Runtime                            │
│                                                                 │
│  ┌──────────────────┐     emit()     ┌───────────────────────┐ │
│  │                  │ ──────────────▶│                       │ │
│  │  Agent/Tools     │                │    EventTarget        │ │
│  │                  │                │  (Event Dispatcher)   │ │
│  └──────────────────┘                │                       │ │
│                                      │  ┌─────────────────┐  │ │
│                                      │  │  Listener 1     │  │ │
│                                      │  │  Listener 2     │  │ │
│                                      │  │  ...            │  │ │
│                                      │  └─────────────────┘  │ │
│                                      └───────────────────────┘ │
│                                                                 │
│  ┌──────────────────┐    poll()      ┌───────────────────────┐ │
│  │                  │ ◀──────────────│                       │ │
│  │  Agent           │                │  ExternalEventQueue   │ │
│  │                  │     send()     │  (External Input)     │ │
│  └──────────────────┘ ◀──────────────│                       │ │
│                          (from env)  └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1. Event (Enum)

The `Event` enum represents all possible events that can occur during an agent's conversation lifecycle. Events are emitted by the agent runtime and can be observed by registered listeners.

**Lifecycle Events:**
- `PreConversation` / `PostConversation` - Conversation boundaries
- `ModelLoaded` - When a model is loaded

**Message Events:**
- `MessageAdded` - When a message is added to the conversation
- `MessageQueued` / `MessageUnqueued` - Message queue operations

**Tool Events:**
- `ToolAdded` - When a tool is registered with the agent
- `PreToolCall` / `PostToolCall` - Tool execution boundaries

**Processing Events:**
- `TokenCounted` - Token counting for context management
- `ContextPruned` - When context pruning is performed
- `RequestCompleted` - When an LLM request completes

**External Events:**
- `ExternalEventReceived` - External event processing
- `Cancelled` - User Cancel
- `TodoUpdated` - Todo list updates

### 2. EventTarget

The `EventTarget` is the central event dispatcher that:
- Maintains an unbounded async queue of events
- Supports multiple listeners via `add_listener()`
- Processes events asynchronously via `start()`
- Provides `flush()` for immediate processing and `close()` for graceful shutdown

### 3. ExternalEventQueue

The `ExternalEventQueue` provides a mechanism for external sources (environment, IDE, user) to send events to the agent:
- `Diagnostics` - IDE diagnostics (errors, warnings)
- `Cancelled` - User wants to cancel the operation
- `UserMessage` - User sends an immediate message

## Conversation Lifecycle

A typical conversation follows this event sequence:

```
MessageAdded (system)     ─┐
MessageAdded (user)        │ Initial setup
                          ─┘
PreConversation           ─── Conversation starts
  │
  ├─▶ ExternalEventReceived (if any)
  │   TokenCounted
  │   ContextPruned
  │   RequestCompleted
  │     │
  │     ├─▶ PreToolCall
  │     │   PostToolCall
  │     │   MessageAdded (tool)
  │     │
  │     └─▶ (loop back if more tool calls)
  │
  └─▶ (loop until conversation complete)
        │
PostConversation          ─── Conversation ends
```

## Usage Patterns

### Listening to Events

```moonbit nocheck
let emitter = EventTarget::new()

// Register a listener
emitter.add_listener(async fn(event) {
  match event {
    PostToolCall(tool_call, result~, rendered~) => 
      // Handle tool completion
    RequestCompleted(usage~, message~) => 
      // Handle LLM response
    _ => ()
  }
})

// Start the event loop (typically in a background task)
emitter.start()
```

### Handling External Events

```moonbit nocheck
let external_queue = ExternalEventQueue::new()

// From environment (e.g., IDE integration)
external_queue.send(Diagnostics(diagnostics))
external_queue.send(Cancelled)

// From agent (polling)
let events = external_queue.poll()
for event in events {
  // Process external events
}
```

## JSON Serialization

All events implement `ToJson` for logging and debugging purposes. Sensitive information (like API keys) is redacted in the JSON output.
