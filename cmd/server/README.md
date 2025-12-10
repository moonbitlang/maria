# Maria HTTP Server

`cmd/server` hosts the lightweight HTTP server that sits in front of the Maria
agent. It exposes REST and SSE endpoints for queueing messages, observing agent
progress, tweaking runtime features (tools, prompts, web search), and managing
local MoonBit modules. A tiny HTML/JS playground (`index.html`, `script.js`)
ships alongside the server for smoke‑testing the API.

## Running locally

```bash
moon run cmd/main -- server --port 8090 --serve cmd/server
```

Once the server starts, visit `http://localhost:8090/` for the playground UI or
call the endpoints directly via `curl`/`http`. Use `--serve` to point at any
directory containing an `index.html` bundle, and set `--web-search` or
registering flags (`--register-*`) when wiring into a daemon.

## Endpoint tour

### Health and task control

- `GET /v1/status` → `{ "status": "idle" | "generating", "web_search": <bool> }`.
- `POST /v1/cancel` → Cancels the active run and returns
  `{ "pending_messages": [...] }`. Responds with 404 when nothing is running.

### Messaging lifecycle

- `POST /v1/message` → Queues an `@ai.Message`. Payload accepts an OpenAI style
  `message` plus optional `web_search`. Response mirrors
  `{ "id": "...", "queued": <bool> }` to indicate whether the request started
  immediately or sits in the backlog.
- `GET /v1/queued-messages` → Returns the serialized queue
  `[ { "id": ..., "message": { ... } }, ... ]`.
- `GET /v1/events` → Server-Sent Events stream. Every connection receives a
  `maria.queued_messages.synchronized` snapshot followed by `event: maria`
  payloads for agent milestones (queued, unqueued, completion, etc.). Tool and
  verbose token events are filtered so frontends only receive user-relevant
  updates.

### External nudges

- `POST /v1/external-event` → Sends a generic external event. Body must include
  `type` (`UserMessage`, `UserCancellation`, `Diagnostics`) plus any extra data
  required by the chosen type.
- `POST /v1/external-event/diagnostics` → Convenience endpoint that accepts
  either a JSONL string or an array of diagnostics objects and forwards it as a
  diagnostics event.
- `POST /v1/external-event/user-message` → Shorthand for injecting a user
  message without enqueuing work.
- `POST /v1/external-event/cancel` → Emits a cancellation external event, which
  causes the agent to stop at the next poll checkpoint.

### Tools and system prompt

- `GET /v1/tools` → Lists all registered tools with their `enabled` flag.
- `POST /v1/enabled-tools` → Accepts an array of tool names; anything omitted is
  disabled. Duplicates raise a 400 error.
- `GET /v1/system-prompt` → Returns the current system prompt or `null` when
  unset.
- `POST /v1/system-prompt` → Accepts a JSON string or `null` to update the
  agent’s system prompt.

### MoonBit helpers

- `GET /v1/moonbit/modules` → Recursively walks the working directory for
  `moon.mod.json` files and returns metadata (`path`, `name`, `version`,
  `description`).
- `POST /v1/moonbit/publish` → Spawns `moon publish` within the provided module
  directory. On success it responds with module metadata plus process output.
  Failures distinguish between “module missing” (404) and process errors (500)
  and include stderr/stdout for debugging.

## Static assets

`index.html` and `script.js` provide a minimal SSE console plus form inputs for
sending messages. They are served from the directory passed via `--serve` and
fall back to static file serving for any other `GET` paths.
