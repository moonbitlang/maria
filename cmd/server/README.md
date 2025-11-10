# HTTP Server

## Run

```bash
moon run cmd/server -- --port 8080 --serve cmd/server
```

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
