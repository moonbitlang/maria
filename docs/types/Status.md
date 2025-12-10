# `Status`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L16)

```ts
export type Status = "idle" | "generating";
```

MoonBit: [`cmd/server/status.mbt`](../../cmd/server/status.mbt)

```mbt
pub(all) enum Status {
  Idle
  Busy
}
```

JSON encoding:

```jsonc
"idle" | "generating"
```

The UI treats a task as either:

- `"idle"` – no model call is currently in flight
- `"generating"` – the daemon is actively processing / streaming a response

The `Status` is attached to `TaskOverview` and is updated via:

- HTTP endpoints (e.g. creating a task)
- SSE events like `daemon.task.changed` (see below)
