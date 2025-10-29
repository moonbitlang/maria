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
  let formatter = Formatter::new(output_path)
  let jsonl_text = @fs.read_file(input_path)
  for json_text in jsonl_text.split("\n").collect() {
    if json_text.trim_space().is_empty() {
      continue
    }
    let json = @json.parse(json_text) catch {
      error => {
        println("Warning: Failed to parse JSON line: \{error}\n\{json_text}")
        continue
      }
    }
    formatter.format_log_entry(json)
  }
  @fs.make_directory(@path.dirname(output_path))
  @fs.write_to_file(output_path, formatter.to_string())
  for tool_formatter in formatter.tools.values().collect() {
    @fs.write_to_file(tool_formatter.path, tool_formatter.to_string())
  }
}
