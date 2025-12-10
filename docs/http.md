# HTTP and SSE endpoints used by the UI

The core React UI (`ui/core`) communicates with the daemon via plain HTTP and
Server‑Sent Events (SSE). The canonical usage lives in
`ui/core/src/features/api/apiSlice.ts`.

All requests are prefixed with a base URL stored in the Redux `urlSlice`.
Below we describe just the paths and payload shapes as seen from the UI.

## `GET /task/:id`

Request is not used.

Response:

```jsonc
{
  "task": TaskOverview
}
```

- TypeScript: [`ui/core/src/features/api/apiSlice.ts#L48`](../ui/core/src/features/api/apiSlice.ts#L48)

  On the UI side, this is called via `useTaskQuery` from `apiSlice`. The query
  issues a `GET` to `task/:id`, then `onQueryStarted` reads `data.task` and
  dispatches `setTask` so the Redux `tasksSlice` holds the latest `TaskOverview`.

- MoonBit: [`cmd/daemon/daemon.mbt#L463`](../cmd/daemon/daemon.mbt#L463)

  On the daemon side, [`Daemon::get_task`](../cmd/daemon/daemon.mbt#L463) looks
  up the task by UUID, serializes it with
  [`Task::to_json_object()`](../cmd/daemon/task.mbt#L110), [augments it with
  `queued_messages()`](../cmd/daemon/daemon.mbt#L482), and [returns a `{ "task":
  ... }` envelope](../cmd/daemon/daemon.mbt#L483) that matches the JSON shape
  consumed by the UI.

## `POST /task`

Request body:

```jsonc
{
  "name": string,          // task name, normally mirrors the first message
  "model": string,         // model identifier (e.g. "anthropic/claude-sonnet-4.5")
  "message": {             // initial user message
    "role": "user",
    "content": string
  },
  "cwd"?: string,          // optional working directory
  "web_search": boolean    // whether web search is enabled for this task
}
```

Response:

```jsonc
{
  "task": TaskOverview
}
```

- [TaskOverview](types.md#taskoverview)
- TypeScript: [`ui/core/src/features/api/apiSlice.ts#L57`](../ui/core/src/features/api/apiSlice.ts#L57)
- MoonBit: [`cmd/daemon/daemon.mbt#L198`](../cmd/daemon/daemon.mbt#L198)

The React UI uses `useNewTaskMutation` to create tasks. The mutation builds the
request body from the initial chat input (`message`), hard‑codes the model
identifier, and optionally includes `cwd` and `web_search`. In MoonBit,
`Daemon::create_task` decodes this JSON, spins up a per‑task Maria `Server`
process, registers it in `by_id`/`by_cwd`, and returns the freshly created
task’s overview as `{ "task": TaskOverview }`. The returned object is then fed
back into the UI task list via RTK Query cache invalidation and the SSE
synchronization described below.

## `POST /task/:id/message`

Request body:

```jsonc
{
  "message": {
    "role": "user",
    "content": string
  },
  "web_search": boolean
}
```

Response:

```jsonc
{
  "id": string,      // server‑side ID of the queued/sent message
  "queued": boolean  // true if the message was queued instead of sent
}
```

- TypeScript: [`ui/core/src/features/api/apiSlice.ts#L81`](../ui/core/src/features/api/apiSlice.ts#L81)

  On the TypeScript side, `usePostMessageMutation` issues a `POST` to
  `task/:id/message` with an OpenAI‑style user message and a `web_search` flag.
  The UI expects an `{ id, queued }` response; if `queued` is `true`, it pushes a
  `QueuedMessage` `{ id, content }` into the per‑task `inputQueue` so the pending
  input appears in the timeline. On the daemon side, the `POST /task/:id/message`
  route is not handled directly; instead, it matches the `(method_, ["", "v1",
  "task", id, .. paths])` arm in `Daemon::serve` and is passed to
  `Daemon::forward_to_task`. That helper resolves the task by UUID, then proxies
  the request to the per‑task HTTP server at
  `http://localhost:<task.port>/v1/message`, streaming the original request body
  through.

- MoonBit: [`cmd/daemon/daemon.mbt#L640`](../cmd/daemon/daemon.mbt#L640),
  [`cmd/server/server.mbt#L140`](../cmd/server/server.mbt#L140),
  [`cmd/server/create_message.mbt#L42`](../cmd/server/create_message.mbt#L42)

  Within the task process, `Server::serve_http` routes `POST /v1/message` to
  `Server::create_message`. The `CreateMessageRequest` struct converts the
  OpenAI‑style JSON into an internal `@ai.Message` (via
  `@ai.Message::from_openai`) and optional `web_search` flag. `create_message`
  enqueues this request onto the agent’s internal `message_queue`, obtains the
  assigned message `id` and whether it started processing immediately (`queued ==
  false`), and returns `{ "id": id, "queued": queued }`. Downstream, when the
  agent later starts processing a queued message, it emits a `MessageUnqueued`
  task event over SSE; the UI’s `taskEvents` listener sees this and removes the
  corresponding `QueuedMessage` entry from `Task.inputQueue`.

## `POST /task/:id/cancel`

- TypeScript: [`ui/core/src/features/api/apiSlice.ts#L98`](../ui/core/src/features/api/apiSlice.ts#L98)

  The React UI calls `usePostCancelMutation` with a `taskId` when the user hits
  the cancel button. This results in a `POST` to `task/:id/cancel`, but the actual
  body of the response is ignored; receiving either data or an error is treated as
  confirmation that the in‑flight generation has stopped, and the task’s `Status`
  is moved back to `"idle"` on the next SSE update.

- MoonBit: [`cmd/daemon/daemon.mbt#L640`](../cmd/daemon/daemon.mbt#L640),
  [`cmd/server/server.mbt#L164`](../cmd/server/server.mbt#L164),
  [`cmd/server/server.mbt#L300`](../cmd/server/server.mbt#L300)

  The daemon does not implement this path directly; it is
  matched by the `(method_, ["", "v1", "task", id, .. paths])` arm and forwarded
  by `Daemon::forward_to_task` as a proxied request to `POST /v1/cancel` on the
  per‑task server. Inside the task process, `Server::serve_http` routes
  `/v1/cancel` to `Server::cancel_maria`, which checks for an active Maria task,
  calls `task.cancel()`, clears pending inputs via `maria.agent.clear_inputs()`,
  and responds with any `pending_messages` that were dropped.

## `GET /events` (SSE)

The UI opens an `EventSource` on `${BASE_URL}/events` and subscribes to
named events:

- `daemon.tasks.synchronized` – full snapshot of tasks

  ```jsonc
  {
    "tasks": TaskOverview[]
  }
  ```

  ```ts
  export type DaemonTaskSyncEvent = {
    tasks: TaskOverview[];
  };
  ```

- `daemon.task.changed` – single task updated or created

  ```jsonc
  {
    "task": TaskOverview
  }
  ```

  ```ts
  export type DaemonTaskChangeEvent = {
    task: TaskOverview;
  };
  ```

These events are decoded into `DaemonTaskSyncEvent` and `DaemonTaskChangeEvent`
respectively and used to keep the task list in sync.

- TypeScript: [`ui/core/src/features/api/apiSlice.ts#L105`](../ui/core/src/features/api/apiSlice.ts#L105)

  On the TypeScript side, `useEventsQuery` establishes a long‑lived
  `EventSource` to `${BASE_URL}/events` inside `onCacheEntryAdded`. The listener
  decodes the JSON payloads as `DaemonTaskSyncEvent` and `DaemonTaskChangeEvent`
  and dispatches `setTasks` / `setTask`, keeping the Redux task list
  synchronized with the daemon

- MoonBit: [`cmd/daemon/daemon.mbt#L28`](../cmd/daemon/daemon.mbt#L28)

  In MoonBit, `Daemon::get_events` sends a `daemon.tasks.synchronized` snapshot
  with all current tasks when a connection is opened, then broadcasts
  `daemon.task.changed` whenever individual tasks are created or updated. This
  SSE stream is purely about task overviews; per‑task conversation state is
  streamed via `/task/:id/events`.

## `GET /task/:id/events` (SSE)

For each active task view, the UI opens an `EventSource` on
`${BASE_URL}/task/:id/events` and subscribes to the event type `"maria"`.

Each event payload is JSON that matches the `TaskEvent` union described in the
next section. The UI de‑duplicates events using their numeric `id` and uses the
event sequence to render the conversation timeline.

- TypeScript: [`ui/core/src/features/api/apiSlice.ts#L142`](../ui/core/src/features/api/apiSlice.ts#L142)

  In the UI, `useTaskEventsQuery` uses `onCacheEntryAdded` to open an
  `EventSource` to `/task/:id/events` for each active task view. Incoming events
  of type `"maria"` are parsed as `TaskEvent` and fed into `pushEventForTask` or
  `removeFromInputQueueForTask`, which updates the per‑task event timeline and
  queued‑message state.

- MoonBit: [`cmd/daemon/daemon.mbt#L640`](../cmd/daemon/daemon.mbt#L640),
  [`cmd/server/server.mbt#L166`](../cmd/server/server.mbt#L166),
  [`cmd/server/server.mbt#L324`](../cmd/server/server.mbt#L324)

  On the daemon side, requests to `/task/:id/events` are again routed through
  [`Daemon::forward_to_task`](../cmd/daemon/daemon.mbt#L640), which proxies them
  to [`GET /v1/events`](../cmd/server/server.mbt#L166) on the per‑task Maria
  `Server`. There, [`Server::get_events`](../cmd/server/server.mbt#L324) sends
  an initial
  [`maria.queued_messages.synchronized`](../cmd/server/server.mbt#L331) event
  followed by an SSE stream of `OutgoingEvent` values (filtered to hide some
  low‑level tokens and subagent tool events) under the `maria` event name. These
  `OutgoingEvent` payloads are exactly what the UI’s `TaskEvent` union models.
