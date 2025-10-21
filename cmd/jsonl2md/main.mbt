///|
async fn main {
  let args = @os.args()
  @backtrace.initialize()
  guard args is [_, .. args] else {
    println("Usage: jsonl2md <log-file> --output <markdown-file>")
    return
  }
  let mut input_path = None
  let mut output_path = None
  loop args {
    ["--output" | "-o", path, .. args] => {
      output_path = Some(path)
      continue args
    }
    [['-', ..] as option, ..] => {
      println("Error: Unknown argument: \{option}")
      return
    }
    [log_file, .. args] => {
      input_path = Some(log_file)
      continue args
    }
    [] => ()
  }
  guard input_path is Some(input_path) else {
    println("Error: <log-file> is required")
    return
  }
  let output_path = if output_path is Some(output_path) {
    output_path
  } else {
    @path.stem(input_path).to_string() + ".md"
  }
  let md_lines = ["# Maria Trajectory", ""]
  let jsonl_text = @fs.read_file(input_path)
  let mut assistant_response_counter = 1
  for json_text in jsonl_text.split("\n") {
    if json_text.trim(char_set=" \t\r\n").is_empty() {
      continue
    }
    let json = @json.parse(json_text) catch {
      error => {
        println("Warning: Failed to parse JSON line: \{error}\n\{json_text}")
        continue
      }
    }
    match json {
      { "msg": "Request completed: Usage", "message": message, .. } => {
        guard message is { "content": String(content), .. } else { return }
        md_lines.push("## Assistant Response \{assistant_response_counter}")
        assistant_response_counter += 1
        let content = content.trim(char_set=" \n\r\t").to_string()
        if content.is_empty() {
          md_lines.push("")
          continue
        } else {
          md_lines.push("")
          md_lines.push(content)
          md_lines.push("")
        }
      }
      { "msg": "PreToolCall", "name": String(name), "args": args, .. } => {
        md_lines.push("### Tool Call: \{name}")
        md_lines.push("")
        md_lines.push("**Arguments:**")
        md_lines.push("")
        md_lines.push("```json")
        md_lines.push(args.stringify(indent=2))
        md_lines.push("```")
        md_lines.push("")
      }
      { "msg": "PostToolCall", "output": output, .. } => {
        md_lines.push("**Tool Result:**")
        md_lines.push("")
        md_lines.push("```json")
        md_lines.push(output.stringify(indent=2))
        md_lines.push("```")
        md_lines.push("")
      }
      _ => ()
    }
  }
  @fs.make_directory(@path.dirname(output_path))
  @fs.write_to_file(output_path, md_lines.join("\n"))
}
