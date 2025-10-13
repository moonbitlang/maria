# `moonbitlang/maria/event`

Generic event target system for emitting and listening to typed events.

## Overview

This package provides a simple event emitter/listener pattern with type-safe event kinds and contexts.

## Usage

### Creating an Event Target

```moonbit
///|
test "create event target" {
  let target : @event.Target[String, Int] = @event.Target::new()
  let _ = target
}
```

### Adding Event Listeners

```moonbit
///|
test "add listener" {
  let target : @event.Target[String, String] = @event.Target::new()
  
  target.add_listener("message", async fn(context) {
    println("Received: \{context}")
  })
  
  let _ = target
}
```

### Emitting Events

```moonbit
///|
test "emit event" {
  let target : @event.Target[String, Int] = @event.Target::new()
  let received = Ref::new(None)
  
  target.add_listener("count", async fn(value) {
    received.val = Some(value)
  })
  
  target.emit("count", 42)
  
  @json.inspect(received.val, content=Some(42))
}
```

### Multiple Listeners

```moonbit
///|
test "multiple listeners" {
  let target : @event.Target[String, String] = @event.Target::new()
  let results = []
  
  target.add_listener("event", async fn(ctx) {
    results.push("listener1: \{ctx}")
  })
  
  target.add_listener("event", async fn(ctx) {
    results.push("listener2: \{ctx}")
  })
  
  target.emit("event", "test")
  
  @json.inspect(results, content=[
    "listener1: test",
    "listener2: test"
  ])
}
```

## API Reference

### Types

#### `Target[Kind, Context]`

An event target that manages listeners for different event kinds.

- **Type Parameters:**
  - `Kind`: The type of event identifiers (must be `Eq + Hash`)
  - `Context`: The type of data passed to listeners

**Methods:**
- `new() -> Target[Kind, Context]`: Creates a new event target
- `add_listener(kind: Kind, f: async (Context) -> Unit)`: Registers a listener for an event kind
- `emit(kind: Kind, context: Context)`: Emits an event to all registered listeners

## Notes

- Event listeners are called asynchronously
- Multiple listeners can be registered for the same event kind
- Listeners are called in the order they were registered
- If no listeners are registered for an event kind, `emit` does nothing
- This is a simple in-memory event system, not persistent
