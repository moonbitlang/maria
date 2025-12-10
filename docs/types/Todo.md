# `Todo`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L120)

```ts
export type Todo = {
  content: string;
  created_at: string; // ISO timestamp
  id: string;
  priority: "High" | "Medium" | "Low";
  status: "Pending" | "Completed" | "InProgress";
  updated_at: string; // ISO timestamp
};
```

MoonBit:

- `Item`: [`tools/todo/types.mbt`](../../tools/todo/types.mbt#L37)

  ```mbt
  priv struct Item {
    content : String
    created_at : String
    id : String
    notes : String?
    priority : Priority
    status : Status
    updated_at : String
  }
  ```

- `Priority` enum: [`tools/todo/types.mbt`](../../tools/todo/types.mbt#L23)

  ```mbt
  priv enum Priority {
    High
    Medium
    Low
  }
  ```

- `Status` enum: [`tools/todo/types.mbt`](../../tools/todo/types.mbt#L30)

  ```mbt
  priv enum Status {
    Pending
    Completed
    InProgress
  }
  ```

JSON encoding (single todo item):

```jsonc
{
  "content": "Write tests",
  "created_at": "2024-01-01T00:00:00Z",
  "id": "todo-1",
  "priority": "High",          // "High" | "Medium" | "Low"
  "status": "Pending",         // "Pending" | "Completed" | "InProgress"
  "updated_at": "2024-01-01T00:00:00Z"
}
```

The daemon emits updates via `TodoUpdated` task events (see `event/event.mbt`).
Todos are managed by the daemon and mirrored into the UI via `TodoUpdated`
task events (see below). The UI treats the daemon as the source of truth and
does not mutate todo fields client‑side.
