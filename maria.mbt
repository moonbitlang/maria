///|
fn main {
  @async.with_event_loop(_ => {
    let args = @sys.get_cli_args()
    if args.length() <= 1 {
      println("Usage: moonagent <prompt>")
    }
    let prompt = args[1:].join(" ")
    let env = @sys.get_env_vars()
    guard env.get("OPENAI_API_KEY") is Some(api_key) else {
      println("Missing OPENAI_API_KEY")
    }
    let body : Json = {
      "messages": [{ "role": "user", "content": prompt }],
      "model": "anthropic/claude-sonnet-4",
      "stream": false,
    }
    let body = body.stringify()
    let body = @encoding.encode(body, encoding=UTF8)
    let (response, body) = @http.post(
      "https://openrouter.ai/api/v1/chat/completions",
      body,
      headers=[
        @http.Header(
          "Authorization",
          @encoding.encode("Bearer \{api_key}", encoding=UTF8),
        ),
        @http.Header("Content-Type", "application/json"),
        @http.Header("Connection", "close"),
      ],
    )
    let body = @encoding.decode(body)
    let json = @json.parse(body)
    guard response.code is (200..=299) else {
      println("HTTP Error: \{response.code}")
    }
    let completion : @openai.ChatCompletion = @json.from_json(json)
    guard completion.choices[0].message.content is Some(content)
    println(content)
  }) catch {
    error => println("Error: \{error}")
  }
}
