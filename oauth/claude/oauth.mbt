///|
struct TokenResponse {
  access_token : String
  refresh_token : String
  expires_in : Int
} derive(Show)

///|
impl @json.FromJson for TokenResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> TokenResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "TokenResponse: expected object"))
  }
  let access_token : String = match obj.get("access_token") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError(
        (path, "TokenResponse: missing 'access_token'"),
      )
  }
  let refresh_token : String = match obj.get("refresh_token") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError(
        (path, "TokenResponse: missing 'refresh_token'"),
      )
  }
  let expires_in : Int = match obj.get("expires_in") {
    Some(Number(n)) => n.to_int()
    _ =>
      raise @json.JsonDecodeError((path, "TokenResponse: missing 'expires_in'"))
  }
  { access_token, refresh_token, expires_in }
}

///|
fn generate_state() -> String {
  let bytes = generate_random_bytes(32)
  strip_padding(@base64.encode(bytes, url_safe=true))
}

///|
fn url_encode(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' | '.' | '~' =>
        buf.write_char(c)
      _ => {
        let bytes = @encoding/utf8.encode(c.to_string())
        for b in bytes {
          let hex = b.to_int()
          let high = (hex >> 4) & 0xF
          let low = hex & 0xF
          let hex_char = fn(n : Int) -> Char {
            if n < 10 {
              ('0'.to_int() + n).unsafe_to_char()
            } else {
              ('A'.to_int() + n - 10).unsafe_to_char()
            }
          }
          buf.write_char('%')
          buf.write_char(hex_char(high))
          buf.write_char(hex_char(low))
        }
      }
    }
  }
  buf.to_string()
}

///|
fn build_authorize_url(pkce : PkceCodes, state : String) -> String {
  let params = [
    ("code", "true"),
    ("client_id", CLIENT_ID),
    ("response_type", "code"),
    ("redirect_uri", REDIRECT_URI),
    ("scope", SCOPES),
    ("code_challenge", pkce.code_challenge),
    ("code_challenge_method", "S256"),
    ("state", state),
  ]
  let query = params
    .iter()
    .map(fn(p) { "\{url_encode(p.0)}=\{url_encode(p.1)}" })
    .collect()
    .join("&")
  "\{OAUTH_AUTHORIZE_URL}?\{query}"
}

///|
/// Parse the authorization code from the format "code#state"
pub fn parse_auth_code(input : String) -> (String, String)? {
  let parts = input.split("#").to_array()
  if parts.length() == 2 {
    Some((parts[0].to_string(), parts[1].to_string()))
  } else {
    None
  }
}

///|
async fn exchange_code_for_tokens(
  code : String,
  state : String,
  pkce : PkceCodes,
) -> TokenResponse raise Error {
  let body : Json = {
    "code": code,
    "state": state,
    "grant_type": "authorization_code",
    "client_id": CLIENT_ID,
    "redirect_uri": REDIRECT_URI,
    "code_verifier": pkce.code_verifier,
  }
  let (response, data) = @http.post(TOKEN_URL, body, headers={
    "Content-Type": "application/json",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise ClaudeOAuthError(
      "Token exchange failed: \{response.code} - \{error_text}",
    )
  }
  @json.from_json(data.json())
}

///|
async fn open_browser(url : String) -> Unit raise Error {
  let result = @spawn.spawn("open", [url])
  if result.status == 0 {
    return
  }
  let result = @spawn.spawn("xdg-open", [url])
  if result.status == 0 {
    return
  }
  ()
}

///|
async fn read_line() -> String {
  let buf = @buffer.new()
  for {
    let bytes = @stdio.stdin.read_some()
    guard bytes is Some(bytes) && bytes.length() > 0 else { break }
    for i in 0..<bytes.length() {
      let byte = bytes[i]
      if byte == b'\n' {
        return buf.to_string()
      }
      buf.write_byte(byte)
    }
  }
  buf.to_string()
}

///|
pub async fn start_oauth_flow() -> Credentials raise Error {
  let pkce = generate_pkce()
  let state = generate_state()
  let auth_url = build_authorize_url(pkce, state)
  println("\nStarting Claude Max authentication...")
  println("\n1. Open this URL in your browser:\n")
  println("   \{auth_url}\n")
  // Try to open browser automatically
  open_browser(auth_url) catch {
    _ => ()
  }
  println(
    "2. After authorizing, you'll be redirected to a page showing an authorization code.",
  )
  println("   The code will be in the format: <code>#<state>")
  println("\n3. Paste the complete code (including the #) here:\n")
  let input = read_line().trim().to_string()
  guard parse_auth_code(input) is Some((code, received_state)) else {
    raise ClaudeOAuthError(
      "Invalid authorization code format. Expected 'code#state'",
    )
  }
  if received_state != state {
    raise ClaudeOAuthError("State mismatch - possible CSRF attack")
  }
  println("\nExchanging code for tokens...")
  let tokens = exchange_code_for_tokens(code, state, pkce)
  let now = @async.now() / 1000L
  let credentials : Credentials = {
    access_token: tokens.access_token,
    refresh_token: tokens.refresh_token,
    expires_at: now + tokens.expires_in.to_int64(),
  }
  save_credentials(credentials)
  println("Claude Max authentication successful!")
  credentials
}

///|
test "parse_auth_code_valid" {
  let input = "abc123#state456"
  guard parse_auth_code(input) is Some((code, state)) else { fail("Expected Some") }
  assert_eq(code, "abc123")
  assert_eq(state, "state456")
}

///|
test "parse_auth_code_invalid" {
  let input = "no_hash_here"
  assert_true(parse_auth_code(input) is None)
}
