# `PostToolCallEvent`

All `PostToolCall` events share a common base and then specialize per tool
name:

TypeScript: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L147)

```ts
type PostToolCallBase = {
  msg: "PostToolCall";
  tool_call: ToolCall;
  text: string;       // human‑readable rendering of the tool result
  result?: unknown;   // machine‑readable result (tool‑specific)
  error?: string;     // optional error description
};

export type PostToolCallEvent = PostToolCallBase &
  | ExecuteCommandTool
  | ListFilesTool
  | ReadFileTool
  | MetaWriteToFileTool
  | UnknownTool;
```

MoonBit: [`event/event.mbt`](../../event/event.mbt#L73)

```mbt
PostToolCall(
  @ai.ToolCall,
  result~ : Result[Json, Json],
  rendered~ : String,
)
```

The UI behavior:

- When a `PostToolCall` is received, it searches backwards in the event list
  for a `PreToolCall` with the same `tool_call.id` and replaces it. This keeps
  the UI timeline compact (“input” → “output” for a given tool call).
- If no matching `PreToolCall` is found, the `PostToolCall` is simply appended
  to the event list.

JSON encoding:

```jsonc
// Successful tool call
{
  "msg": "PostToolCall",
  "tool_call": {
    "id": "call_123",
    "type": "function",
    "function": { "name": "read_file", "arguments": "{...}" }
  },
  "name": "read_file",
  "result": { /* tool‑specific payload, see below */ },
  "text": "Read 42 lines from README.md"
}

// Failed tool call
{
  "msg": "PostToolCall",
  "tool_call": { /* same as above */ },
  "name": "read_file",
  "error": { /* JSON error payload */ },
  "text": "Error: file not found"
}
```

Tool‑specific shapes are described in the next section.

The following are specializations of `PostToolCallEvent` used by the UI to
render richer visualizations.

## `ExecuteCommandTool` – `execute_command`

TypeScript definition: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L79).

```ts
export type ExecuteCommandTool = {
  name: "execute_command";
  result: [
    "Completed",
    {
      command: string;
      status: number;         // process exit code
      stdout: string;         // captured stdout
      stderr: string;         // captured stderr
      max_output_lines: number; // truncation hint
    },
  ];
  error?: unknown;
};
```

MoonBit definition: [`tools/execute_command/tool.mbt`](../../tools/execute_command/tool.mbt#L9).

```mbt
pub enum CommandResult {
  Completed(
    command~ : String,
    status~ : Int,
    stdout~ : String,
    stderr~ : String,
    max_output_lines~ : Int
  )
  TimedOut(
    command~ : String,
    timeout~ : Int,
    stdout~ : String,
    stderr~ : String,
    max_output_lines~ : Int
  )
  Background(command~ : String, job_id~ : @job.Id)
} derive(@json.FromJson, ToJson)
```

The UI:

- Shows the command, exit code, and separate sections for stdout / stderr
- Treats `status === 0` as success, anything else as error

JSON encoding (`PostToolCall.result` for `execute_command`):

```jsonc
{
  "name": "execute_command",
  "result": [
    "Completed",
    {
      "command": "moon test",
      "status": 0,
      "stdout": "...",
      "stderr": "",
      "max_output_lines": 2000
    }
  ],
  "error": null
}
```

## `ListFilesTool` – `list_files`

TypeScript definition: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L94).

```ts
export type ListFilesTool = {
  name: "list_files";
  result: {
    path: string; // directory that was listed
    entries: { name: string; kind: string; is_hidden: boolean }[];
    total_count: number;
    file_count: number;
    directory_count: number;
  };
};
```

MoonBit definition: [`tools/list_files/list_files.mbt`](../../tools/list_files/list_files.mbt#L1).

```mbt
///|
/// File entry with metadata for enhanced list_files output
priv struct FileEntry {
  name : String
  kind : String // "file", "directory", "symlink", etc.
  size : Int? // Size in bytes for files, None for directories
  is_hidden : Bool
} derive(ToJson, FromJson)

///|
/// Enhanced list_files result with metadata
struct ListFilesResult {
  path : String
  entries : Array[FileEntry]
  total_count : Int
  file_count : Int
  directory_count : Int
} derive(ToJson, FromJson)
```

Rendered as a scrollable list with per‑entry icons and summary badges for
total / file / directory counts.

JSON encoding (`PostToolCall.result` for `list_files`):

```jsonc
{
  "name": "list_files",
  "result": {
    "path": ".", // listed directory
    "entries": [
      { "name": "README.md", "kind": "file", "is_hidden": false },
      { "name": "src", "kind": "directory", "is_hidden": false }
    ],
    "total_count": 2,
    "file_count": 1,
    "directory_count": 1
  }
}
```

## `ReadFileTool` – `read_file`

TypeScript definition: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L105).

```ts
export type ReadFileTool = {
  name: "read_file";
  result: {
    path: string;      // file path
    content: string;   // full file content
    start_line: number;
    end_line: number;
  };
};
```

MoonBit definition: [`tools/read_file/read_file.mbt`](../../tools/read_file/read_file.mbt#L2).

```mbt
///|
struct ReadFileToolResult {
  path : String
  content : String
  start_line : Int
  end_line : Int
} derive(ToJson, FromJson)
```

Displayed as a code block, with the language inferred from the file
extension (fallback to `plaintext`).

JSON encoding (`PostToolCall.result` for `read_file`):

```jsonc
{
  "name": "read_file",
  "result": {
    "path": "README.md",
    "content": "...full file contents...",
    "start_line": 1,
    "end_line": 200
  }
}
```

## `MetaWriteToFileTool` – `meta_write_to_file`

TypeScript definition: [`ui/core/src/lib/types.ts`](../../ui/core/src/lib/types.ts#L115).

```ts
export type MetaWriteToFileTool = {
  name: "meta_write_to_file";
  result: {
    path: string;     // file that was (or will be) written
    message: string;  // human readable summary
    diff?: string;    // optional unified diff string
  };
};
```

MoonBit definition: [`tools/meta_write_to_file/types.mbt`](../../tools/meta_write_to_file/types.mbt).

```mbt
///|
pub struct MetaWriteToFileResult {
  path : String
  message : String
  diff : String?
  learning_prompt : String?
} derive(ToJson, FromJson)
```

The UI shows `message` and, if present, renders `diff` as a syntax‑highlighted
`diff` code block.

JSON encoding (`PostToolCall.result` for `meta_write_to_file`):

```jsonc
{
  "name": "meta_write_to_file",
  "result": {
    "path": "src/index.ts",
    "message": "Planned edits for src/index.ts",
    "diff": "--- a/src/index.ts\n+++ b/src/index.ts\n..."
  }
}
```

### Other tools

Tools with unrecognized `name` values are still rendered using the generic
`text` field of `PostToolCallEvent`, wrapped as a Markdown block. If a tool is
named `"todo"`, the UI deliberately does **not** render a separate tool box,
since todo updates are handled via `TodoUpdatedEvent` instead.
