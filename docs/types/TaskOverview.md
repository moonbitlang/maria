# `TaskOverview`

TypeScript: Defined in
[`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L18). Also used in
`ui/core/src/features/api/apiSlice.ts` (HTTP client) and in SSE payloads emitted
by the daemon.

```ts
export type TaskOverview = {
  id: string;
  name: string;
  status: Status;
  created: number; // ms since epoch
  cwd: string; // absolute path on the daemon host
};
```

MoonBit:

- `Task`: Defined in [`cmd/daemon/task.mbt`](../../cmd/daemon/task.mbt#L1).

  ```mbt
  priv struct Task {
    name : String?
    id : @uuid.Uuid
    cwd : String
    port : Int
    mut status : @server.Status
    created : Int64
    web_search : Bool
  }
  ```

- `@server.Status`: See [Status](../../types/Status.md).

JSON:

```json
{
  "name": "example" | null,
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "cwd": "/tmp/example",
  "port": 8080,
  "status": "idle",
  "created": 0,
  "web_search": true,
}
```

`TaskOverview` is the compact representation used:

- In task lists (all frontends)
- In daemon → UI synchronization events

It does **not** include conversation history or todos; those live in
per‑task state on the UI side.
