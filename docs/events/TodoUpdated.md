# `TodoUpdatedEvent`

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L42)

```ts
type TodoUpdatedEvent = {
  msg: "TodoUpdated";
  todo: {
    todos: Todo[];
    created_at: string;
    updated_at: string;
  };
};
```

Whenever the daemon updates the agent TODO list (for example via a special
tool), it emits `TodoUpdated`. The UI replaces its local `Task.todos` array
with `todo.todos` and displays them in the “Agent TODOs” panel.

MoonBit:

- `TodoUpdated`: [`event/event.mbt`](../../event/event.mbt#L100),

  ```mbt
  /// Event triggered when the todo list is updated.
  TodoUpdated(Json)
  ```

- `Items`: [`tools/todo/types.mbt`](../../tools/todo/types.mbt#L16),

  ```mbt
  pub struct Items {
    todos : [Item]
    created_at : String
    updated_at : String
  } derive(ToJson, FromJson, Eq)
  ```

- `Item`: See [Todo](../types/Todo.md).

JSON encoding:

```jsonc
{
  "msg": "TodoUpdated",
  "todo": {
    "todos": Todo[],
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:01:00Z"
  }
}
```
