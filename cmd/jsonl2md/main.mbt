///|
fn json2xml(json : Json, indent? : Int = 0, output : Array[String]) -> Unit {
  match json {
    Object(object) =>
      for key, value in object {
        output.push(" ".repeat(indent) + "<\{key}>")
        json2xml(value, indent=indent + 2, output)
        output.push(" ".repeat(indent) + "</\{key}>")
      }
    Array(array) =>
      // TODO: it might be not correct to just output array items directly, but
      // for now this is much more readable than:
      //
      // ```xml
      // <item>
      //   ...
      // </item>
      // <item>
      //   ...
      // </item>
      // ...
      // ```
      //
      // so we keep it as is.
      for item in array {
        json2xml(item, indent~, output)
      }
    String(string) =>
      for line in string.split("\n") {
        if line.is_empty() {
          output.push("")
        } else {
          output.push([.." ".repeat(indent), ..line])
        }
      }
    Number(_, repr=Some(repr)) => output.push(" ".repeat(indent) + repr)
    Number(value, repr=None) =>
      output.push(" ".repeat(indent) + value.to_string())
    True => output.push(" ".repeat(indent) + "true")
    False => output.push(" ".repeat(indent) + "false")
    Null => output.push(" ".repeat(indent) + "null")
  }
}

///|
test "json2xml" {
  let lines = []
  json2xml({ "greeting": "hello", "items": [1, 2, 3], "active": true }, lines)
  inspect(
    lines.join("\n"),
    content=(
      #|<greeting>
      #|  hello
      #|</greeting>
      #|<items>
      #|  1
      #|  2
      #|  3
      #|</items>
      #|<active>
      #|  true
      #|</active>
    ),
  )
  lines.clear()
  json2xml([1, "A", true, null], lines)
  inspect(
    lines.join("\n"),
    content=(
      #|1
      #|A
      #|true
      #|null
    ),
  )
}

///|
fn format_log_entry(
  json : Json,
  msg_cnt~ : Ref[Int],
  md_lines : Array[String],
) -> Unit raise {
  match json {
    { "msg": "RequestCompleted", "message": message, .. } => {
      let message : @openai.ChatCompletionMessage = @json.from_json(message)
      let content = message.content
        .unwrap_or("")
        .trim(char_set=" \n\r\t")
        .to_string()
      let title = content.split("\n").drop_while(line => line.is_blank()).peek()
      if title is Some(title) {
        md_lines.push("# \{msg_cnt.val} Assistant: \{title}")
        msg_cnt.val += 1
        md_lines.push("")
        md_lines.push(content)
        md_lines.push("")
      } else {
        md_lines.push("# \{msg_cnt.val} Assistant")
        msg_cnt.val += 1
        if !content.is_empty() {
          md_lines.push(content)
        }
        md_lines.push("")
      }
      if message.tool_calls.length() > 0 {
        for tool_call in message.tool_calls {
          md_lines.push("## Tool call argument: <\{tool_call.function.name}>")
          md_lines.push("")
          try {
            let args = @json.parse(tool_call.function.arguments)
            json2xml(args, md_lines)
          } catch {
            _ => {
              md_lines.push(tool_call.function.arguments)
              continue
            }
          }
          md_lines.push("")
        }
      }
    }
    { "msg": "PostToolCall", "name": String(name), "text": String(text), .. } => {
      md_lines.push("# \{msg_cnt.val} Tool call result: <\{name}>")
      msg_cnt.val += 1
      md_lines.push("")
      md_lines.push("```")
      md_lines.push(text)
      md_lines.push("```")
      md_lines.push("")
    }
    { "msg": "MessageAdded", "message": message, .. } => {
      let message : @openai.ChatCompletionMessageParam = @json.from_json(
        message,
      )
      let role = openai_message_role(message)
      let content = openai_message_content(message)
        .trim(char_set=" \n\r\t")
        .to_string()
      md_lines.push("# \{msg_cnt.val} \{role}: \{content}")
      msg_cnt.val += 1
      md_lines.push("")
      md_lines.push(content)
      md_lines.push("")
    }
    _ => ()
  }
}

///|
test "format_log_entry/MessageAdded" {
  let md_lines = []
  let msg_cnt = Ref::new(1)
  let log_entry : Json = {
    "msg": "MessageAdded",
    "message": {
      "role": "user",
      "content": [{ "type": "text", "text": "Hello, how are you?" }],
    },
  }
  format_log_entry(log_entry, msg_cnt~, md_lines)
  inspect(
    md_lines.join("\n"),
    content=(
      #|# 1 User: Hello, how are you?
      #|
      #|Hello, how are you?
      #|
    ),
  )
}

///|
test "format_log_entry/RequestCompleted" {
  let md_lines = []
  let msg_cnt = Ref::new(1)
  let log_entry : Json = {
    "msg": "RequestCompleted",
    "message": {
      "role": "assistant",
      "content": "I am fine, thank you!",
      "tool_calls": [
        {
          "id": "tool_call_1",
          "function": {
            "name": "get_weather",
            "arguments": "{\"location\": \"New York\"}",
          },
        },
      ],
    },
  }
  format_log_entry(log_entry, msg_cnt~, md_lines)
}

///|
test "format_log_entry/PostToolCall" {
  let md_lines = []
  let msg_cnt = Ref::new(1)
  let log_entry : Json = {
    "msg": "PostToolCall",
    "name": "get_weather",
    "text": "The weather in New York is sunny.",
  }
  format_log_entry(log_entry, msg_cnt~, md_lines)
  inspect(
    md_lines.join("\n"),
    content=(
      #|# 1 Tool call result: <get_weather>
      #|
      #|```
      #|The weather in New York is sunny.
      #|```
      #|
    ),
  )
}

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
  let md_lines = []
  let msg_cnt = Ref::new(0)
  let jsonl_text = @fs.read_file(input_path)
  for json_text in jsonl_text.split("\n") {
    if json_text.trim_space().is_empty() {
      continue
    }
    let json = @json.parse(json_text) catch {
      error => {
        println("Warning: Failed to parse JSON line: \{error}\n\{json_text}")
        continue
      }
    }
    format_log_entry(json, msg_cnt~, md_lines)
  }
  @fs.make_directory(@path.dirname(output_path))
  @fs.write_to_file(output_path, md_lines.join("\n"))
}

///|
fn openai_message_role(message : @openai.ChatCompletionMessageParam) -> String {
  match message {
    User(_) => "User"
    Assistant(_) => "Assistant"
    System(_) => "System"
    Tool(_) => "Tool"
  }
}

///|
fn openai_message_content(
  message : @openai.ChatCompletionMessageParam,
) -> String {
  match message {
    User(user_message) => {
      let builder = StringBuilder::new()
      for part in user_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
    Assistant(assistant_message) => {
      let builder = StringBuilder::new()
      for part in assistant_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
    System(system_message) => {
      let builder = StringBuilder::new()
      for part in system_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
    Tool(tool_message) => {
      let builder = StringBuilder::new()
      for part in tool_message.content {
        if part is Text(text) {
          builder.write_string(text.text)
        }
      }
      builder.to_string()
    }
  }
}
