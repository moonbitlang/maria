# Daemon Server

## Run

From the root directory of the repository, run:

```bash
moon run cmd/daemon -- --port 8090 --serve cmd/daemon
```

## API

### `GET /v1/agents`

Returns a list of all active agent instances.

```json
{
  "agents": [
    {
      "name": "example-agent",
      "id": "some-unique-id",
      "cwd": "/path/to/working/directory",
      "port": 8080
    },
    {
      "name": "another-agent",
      "id": "another-unique-id",
      "cwd": "/another/working/directory",
      "port": 8081
    }
  ]
}
```

### `POST /v1/agent`

Creates to an agent instance if the cwd is not yet associated with an existing
agent. Attach to the existing agent spawned on cwd otherwise.

Request:

```json
{
  "name": "example-agent",
  "model": "anthropic/claude-sonnet-4",
  "cwd": "/path/to/working/directory"
}
```

Response:

- If the agent is created successfully, returns HTTP 201 Created.

  ```json
  {
    "agent": {
      "name": "example-agent",
      "id": "some-unique-id",
      "cwd": "/path/to/working/directory",
      "port": 8080
    }
  }
  ```

- If there is already an existing agent on the specified cwd, returns HTTP 409
  Conflict.

  ```json
  {
    "agent": {
      "name": "example-agent",
      "id": "some-unique-id",
      "cwd": "/path/to/working/directory",
      "port": 8080
    }
  }
  ```

### `GET /v1/agent/{id}/events`

Streams events related to the specified agent instance.

### `POST /v1/agent/{id}/message`

Sends a message to the specified agent instance.

```json
{
  "message": {
    "role": "user",
    "content": "Write a JSON parser in MoonBit."
  }
}
```

### `POST /v1/agent/{id}/publish`

Run `moon publish` in the agent's working directory.

```json
{
  "process": {
    "status": 0,
    "stdout": "Published successfully.",
    "stderr": ""
  }
}
```
