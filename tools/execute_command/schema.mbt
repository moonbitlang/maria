///|
let schema : @tool.JsonSchema = {
  "type": "object",
  "properties": {
    "command": {
      "type": "string",
      "description": "The shell command to execute",
    },
    "timeout": {
      "type": "number",
      "description": "The timeout in milliseconds for the shell command to execute. This field is required if the command is executed in foreground (background=false).",
      "default": 1000,
    },
    "max_output_lines": {
      "type": "number",
      "description": "The maximum number of output lines to return directly. If the output exceeds this number, it will be truncated and saved to a file.",
      "default": 100,
    },
    "background": {
      "type": "boolean",
      "description": "Whether to run the command in the background (non-blocking). If true, the tool will return immediately after starting the command.",
      "default": false,
    },
  },
  "required": ["command", "timeout"],
}
