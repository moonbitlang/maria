# HTTP Server

This is a simple HTTP server that exposes an endpoint for sending messages to
the Maria agent and another endpoint for receiving server-sent events (SSE) from
the agent. It comes with a simple HTML frontend for testing the API.

## Run

From the root directory of the repository, run:

```bash
moon run cmd/server -- --port 8080 --serve cmd/server
```

Then open `http://localhost:8080` in your web browser to access the HTML
frontend.

## `POST /v1/message`

Request:

```json
{
  "message": {
    "role": "user",
    "content": "Hello, world!"
  }
}
```

## `GET /v1/events`

```plaintext
event: maria
data: <json>
```

Example JSON objects:

```jsonl
{"level":30,"pid":79372,"msg":"TokenCounted","hostname":"localhost","time":1762763278519,"tag":"server","token_count":16984}
{"level":30,"pid":79372,"msg":"ContextPruned","hostname":"localhost","time":1762763278519,"tag":"server","origin_token_count":16984,"pruned_token_count":16984}
```

For concrete JSON object formats, refer to the code of `maria`.
