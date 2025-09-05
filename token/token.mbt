///|
struct Counter {
  encoding : @tiktoken.Encoding
}

///|
pub fn Counter::new() -> Counter raise {
  { encoding: @tiktoken.cl100k_base() }
}

///|
fn Counter::count_string(self : Counter, text : String) -> Int raise {
  self.encoding.encode(text).length()
}

///|
fn Counter::count_content_parts(
  self : Counter,
  parts : Array[@openai.ChatCompletionContentPartParam],
) -> Int raise {
  let mut count = 0
  for part in parts {
    match part {
      Text(text) => count += self.count_string(text.text)
    }
  }
  count
}

///|
fn Counter::count_message(
  self : Counter,
  message : @openai.ChatCompletionMessageParam,
) -> Int raise {
  match message {
    Assistant(assistant) => self.count_content_parts(assistant.content)
    User(user) => self.count_content_parts(user.content)
    System(system) => self.count_content_parts(system.content)
    Tool(tool) => self.count_content_parts(tool.content)
  }
}

///|
pub fn Counter::count_messages(
  self : Counter,
  messages : Array[@openai.ChatCompletionMessageParam],
) -> Int raise {
  let mut total = 0
  for message in messages {
    total += self.count_message(message)
  }
  total
}
