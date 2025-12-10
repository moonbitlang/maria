# Daemon Server

## Run

From the root directory of the repository, run:

```bash
moon run cmd/main -- daemon --port 8090 --serve cmd/daemon
```

It will first test if there is a running instance of the daemon server by
reading the `~/.moonagent/daemon.json` file. If there is no running instance, it
will start a new one (detach from the terminal if `--detach` flag is specified);
if there is a running instance, it exit immediately.

To detach the daemon from the terminal, you can use `--detach` flag:

```bash
moon run cmd/main -- daemon --port 8090 --serve cmd/daemon --detach
```

Consumers of this daemon server would typically spawn the daemon server with
random port (`--port 0`) and `--detach` flag, as it provides a uniformed way
to spawn and obtain the port of the daemon server:

1. Spawn the daemon server with:

   ```bash
   moon run cmd/main -- daemon --port 0 --serve cmd/daemon --detach
   ```

2. Read the port from the `~/.moonagent/daemon.json` file. Once the process
   exits with `0`, The file is guaranteed to exist and contains a valid JSON
   object with the `port` and `pid` fields.

   ```json
   {
     "port": 8090,
     "pid": 12345
   }
   ```

3. Interact with the daemon server using the port obtained from the file.

## API

### `GET /v1/events`

Streams server-sent events (SSE) related to all agent instances.

```plaintext
event: daemon.tasks.synchronized
data: { "tasks": [<task1>, <task2>, ...] }

event: daemon.task.changed
data: { "task": <task> }
```

### `GET /v1/models`

Returns a list of available models.

```json
{
  "models": [
    {
      "name": "anthropic/claude-sonnet-4"
    }
  ]
}
```

### `GET /v1/tasks`

Returns a list of all active agent instances.

```json
{
  "tasks": [
    {
      "name": "example-agent",
      "id": "some-unique-id",
      "cwd": "/path/to/working/directory",
      "port": 8080,
      "status": "idle",
      "created": 1625247600
    },
    {
      "name": "another-task",
      "id": "another-unique-id",
      "cwd": "/another/working/directory",
      "port": 8081,
      "status": "generating",
      "created": 1625247600
    }
  ]
}
```

### `POST /v1/task`

Creates to a task instance if the cwd is not yet associated with an existing
task. Attach to the existing task spawned on cwd otherwise.

- `name` is optional and purely informational. If not supplied, a empty string
  `""` will be used.

- `model` specifies the model to use for the task. It must be one of the models
  returned by `GET /v1/models`. If not specified, a default model will be used.

- `message` is the initial message to send to the task upon creation. This
  internally calls the `/v1/task/{id}/message` endpoint after the task is created
  or attached to.

- If `cwd` is supplied, a task is created (or attached to) in the specified
  working directory. If not supplied, a temporary directory is created for the
  task.

- `web_search` specifies whether to enable web search plugin for the task. If not
  supplied, defaults to `false`. Note that this option is persistent for the
  task and affects all subsequent requests to the agent.

Request:

```json
{
  "name": "example-task",
  "model": "anthropic/claude-sonnet-4",
  "cwd": "/path/to/working/directory",
  "message": {
    "role": "user",
    "content": "Write a JSON parser in MoonBit."
  },
  "web_search": true
}
```

Response:

- If the task is created successfully, returns HTTP 201 Created.

  ```json
  {
    "task": {
      "name": "example-task",
      "id": "some-unique-id",
      "cwd": "/path/to/working/directory",
      "port": 8080,
      "queued_messages": [],
      "web_search": true
    }
  }
  ```

- If there is already an existing task on the specified cwd, returns HTTP 409
  Conflict.

  ```json
  {
    "task": {
      "name": "example-task",
      "id": "some-unique-id",
      "cwd": "/path/to/working/directory",
      "port": 8080,
      "queued_messages": [],
      "web_search": true
    }
  }
  ```

If there are queued messages, the response would look like this:

```json
{
  "task": {
    "queued_messages": [
      {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "message": {
          "role": "user",
          "content": "Write a JSON parser in MoonBit."
        }
      }
    ]
  }
}
```

### `GET /v1/task/{id}`

Note that `"name"`/`"cwd"`/`"port"` can be `null` or unset.

Response:

```json
{
  "task": {
    "name": "example-task",
    "id": "some-unique-id",
    "cwd": "/path/to/working/directory",
    "port": 8080
  }
}
```

### `GET /v1/task/{id}/events`

Streams events related to the specified task instance.

### `POST /v1/task/{id}/message`

Sends a message to the specified task instance.

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
    "content": "Write a JSON parser in MoonBit."
  }
}
```

### `POST /v1/task/{id}/cancel`

Cancels the current generation of the specified task instance.

If there is no ongoing task, i.e. current status is `"idle"`, returns 404 Not
Found:

```json
{
  "error": {
    "code": -1,
    "message": "No ongoing task to cancel."
  }
}
```

### `POST /v1/task/{id}/publish`

Run `moon publish` in the task's working directory.

```json
{
  "process": {
    "status": 0,
    "stdout": "Published successfully.",
    "stderr": ""
  }
}
```

### `GET /v1/task/{id}/moonbit/modules`

Returns the list of MoonBit modules in the task's working directory.

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

### `POST /v1/moonbit/publish`

Runs `moon publish` in the task's working directory.

```json
{
  "module": {
    "path": "/path/to/moonbit/module"
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

### `POST /v1/shutdown`

Shuts down the daemon server gracefully.
