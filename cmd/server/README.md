# HTTP Server

This is a simple HTTP server that exposes an endpoint for sending messages to
the Maria agent and another endpoint for receiving server-sent events (SSE) from
the agent. It comes with a simple HTML frontend for testing the API.

## Run

From the root directory of the repository, run:

```bash
moon run cmd/main -- server --port 8090 --serve cmd/server
```

Then open `http://localhost:8080` in your web browser to access the HTML
frontend.

## `POST /v1/message`

Request:

- `message`: The message to send to the Maria agent. It should be a JSON object
  with `role` as `"user"` and a non-empty `content` fields.
- `web_search` (optional): A boolean flag to enable web search for this message.
  Note that web search specified this way only affect request caused by this
  message, and does not change `web_search` state of the agent.

```json
{
  "message": {
    "role": "user",
    "content": "Hello, world!"
  },
  "web_search": true
}
```

Response:

```json
{
  "id": "<message-id>",
  "queued": true // or false
}
```

## `GET /v1/queued-messages`

Response:

```json
[
  "<queued-message-0>",
  "<queued-message-1>",
  ...
]
```

Where `<queued-message-i>` is a JSON object:

```json
{
  "id": "<message-id>",
  "message": {
    "role": "user",
    "content": "Hello, world!"
  }
}
```

## `POST /v1/cancel`

Cancels the current message processing task.

If there is no ongoing task, returns 404 Not Found:

```json
{
  "error": {
    "code": -1,
    "message": "No ongoing task to cancel."
  }
}
```

## `GET /v1/events`

```plaintext
event: maria
data: <event>

event: maria.queued_messages.synchronized
data: [<queued-message-0>, <queued-message-1>, ...]
```

`<queued_messages-i>` is a JSON object:

```json
{
  "id": "<message-id>",
  "message": {
    "role": "user",
    "content": "Hello, world!"
  }
}
```

`<event>` is a JSON object representing various events emitted by the Maria
agent, such as `MessageAdded`, `MessageQueued`, `MessageUnqueued`, `PreConversation`,
`RequestCompleted`, `TokenCounted`, and `ContextPruned`. For example:

```jsonl
{"level":30,"pid":79372,"msg":"TokenCounted","hostname":"localhost","time":1762763278519,"tag":"server","token_count":16984}
{"level":30,"pid":79372,"msg":"ContextPruned","hostname":"localhost","time":1762763278519,"tag":"server","origin_token_count":16984,"pruned_token_count":16984}
```

For concrete JSON object formats, refer to the code of `maria`.

## `GET /v1/moonbit/modules`

Returns the list of MoonBit modules in the server's working directory.

Response:

```json
{
  "modules": [
    {
      "path": "/path/to/moonbit/module",
      "name": "example-module",
      "version": "1.0.0",
      "description": "An example module."
    }
  ]
}
```

## `POST /v1/moonbit/publish`

Runs `moon publish` in the server's working directory.

```json
{
  "module": {
    "path": "/path/to/moonbit/module"
  }
}
```

If it fails to find such a module, returns 404 Not Found:

```json
{
  "error": {
    "code": -1,
    "message": "No MoonBit module found in path."
  }
}
```

If successful, returns 201 Created:

```json
{
  "module": {
    "name": "example-module",
    "version": "1.0.0",
    "description": "An example module.",
  },
  "process": {
    "status": 0,
    "stdout": "Published successfully.",
    "stderr": ""
  }
}
```

If failed, returns 500 Internal Server Error:

```json
{
  "error": {
    "code": -1,
    "message": "Failed to publish the module.",
    "metadata": {
      "module": {
        "name": "example-module",
        "version": "1.0.0",
        "description": "An example module.",
      },
      "process": {
        "status": 1,
        "stdout": "",
        "stderr": "Error: Failed to publish."
      }
    }
  },
}
```

## `GET /v1/tools`

Returns the list of tools available in the server's working directory.

```json
{
  "read_files": {
    "enabled": true,
  },
  "write_to_file": {
    "enabled": true,
  },
  "execute_command": {
    "enabled": true,
  }
}
```

## `POST /v1/enabled-tools`

Sets the list of available tools. Tools not included in the list will be disabled.

Request:

```json
[
  "read_files",
  "write_to_file",
]
```
