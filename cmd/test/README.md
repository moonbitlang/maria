# test

Runner for a single prompt against Maria, producing a JSONL activity log you can later inspect or convert to Markdown.

## Usage

```bash
moon run cmd/test -- --prompt-file <prompt-file> [--log-file <log-file>]
```

Arguments:

- `--prompt-file <path>`: Required. Path to a text/markdown file containing the initial prompt fed to Maria.
- `--log-file <path>`: Optional. Destination for the JSONL log. If omitted, a file named `maria_test_log_<timestamp>.jsonl` is created in the current working directory. The timestamp uses the system clock and is formatted as a plain date time (e.g. `2025-10-21T04:42:38`).

Exit codes: This tool prints errors for invalid arguments and exits early; it does not currently set specialized non‑zero codes beyond the runtime defaults.

## Example

Create a prompt file:

```bash
cat > prompt.md <<'EOF'
You are an assistant; respond briefly.
What is the capital of France?
EOF
```

Run the test:

```bash
moon run cmd/test -- --prompt-file prompt.md
# Produces: maria_test_log_2025-10-21T04:42:38.jsonl (name will vary)
```

Specify a custom log file:

```bash
moon run cmd/test -- --prompt-file prompt.md --log-file session.jsonl
```

## Log Format

The log file is line‑delimited JSON (JSONL). Each non‑blank line is one event produced during the session. Each event has the following structure:

```json
{
  "id": "<uuid>",
  "desc": { "msg": "<event-type>", ... }
}
```

The `desc` field contains the event description with a `msg` field indicating the event type. Event types include:

- **Session events**:
  - `ModelLoaded`: Triggered when a model is loaded (includes `name` and `model` fields)
  - `SystemPromptSet`: Triggered when the system prompt is set (includes `prompt` field)

- **Maria conversation events** (wrapped in the `desc` object):
  - `PreConversation`: Before a conversation starts
  - `PostConversation`: After a conversation ends
  - `AssistantMessage`: Assistant responses (may include tool calls)
  - `PreToolCall`: Before a tool is called
  - `PostToolCall`: After a tool call completes (includes result and rendered output)
  - `UserMessage`: User messages
  - `MessageQueued`: When a message is queued to be sent
  - `MessageUnqueued`: When a message is unqueued from pending queue
  - `TokenCounted`: Token counting events
  - `ContextPruned`: Context pruning operations
  - And others...

Selected event types are consumable by the `jsonl2md` converter for producing readable session transcripts.

## Converting Log to Markdown

Use the companion tool in `cmd/jsonl2md`:

```bash
moon run cmd/jsonl2md -- maria_test_log_2025-10-21T04:42:38.jsonl --output session.md
```

If `--output` is omitted, `jsonl2md` writes `<input-stem>.md` next to the source file.

### Sample Conversion

Given a trimmed JSONL (illustrative only):

```jsonl
{"id":"123e4567-e89b-12d3-a456-426614174000","desc":{"msg":"UserMessage","content":"What is the capital of France?"}}
{"id":"123e4567-e89b-12d3-a456-426614174001","desc":{"msg":"AssistantMessage","content":"Paris is the capital of France.","usage":null,"tool_calls":[]}}
```

Conversion produces Markdown like:

````markdown
# 1 User: What is the capital of France?

What is the capital of France?

# 2 Assistant: Paris is the capital of France.

Paris is the capital of France.
````

## Tips

- Keep prompts small and focused; extremely large prompts will impact response latency.
- Preserve the generated JSONL log for reproducibility or regression comparisons.
- You can version logs or diffs by checking them into a separate directory ignored by VCS.

## Future Improvements

Potential enhancements: structured exit codes, streaming output, log schema docs, autosummary after run.
