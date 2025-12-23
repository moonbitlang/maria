///|
struct TokenResponse {
  id_token : String
  access_token : String
  refresh_token : String
} derive(Show)

///|
impl @json.FromJson for TokenResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> TokenResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "TokenResponse: expected object"))
  }
  let id_token : String = match obj.get("id_token") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError((path, "TokenResponse: missing 'id_token'"))
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
  { id_token, access_token, refresh_token }
}

///|
pub suberror OAuthError {
  OAuthError(String)
} derive(Show)

///|
fn generate_state() -> String {
  let bytes = generate_random_bytes(32)
  strip_padding(@base64.encode(bytes, url_safe=true))
}

///|
pub fn build_authorize_url(pkce : PkceCodes, state : String) -> String {
  let params = [
    ("response_type", "code"),
    ("client_id", CLIENT_ID),
    ("redirect_uri", REDIRECT_URI),
    ("scope", "openid profile email offline_access"),
    ("code_challenge", pkce.code_challenge),
    ("code_challenge_method", "S256"),
    ("state", state),
    ("id_token_add_organizations", "true"),
    ("codex_cli_simplified_flow", "true"),
  ]
  let query = params
    .iter()
    .map(fn(p) { "\{url_encode(p.0)}=\{url_encode(p.1)}" })
    .collect()
    .join("&")
  "\{OAUTH_ISSUER}/oauth/authorize?\{query}"
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
pub async fn exchange_code_for_tokens(
  code : String,
  pkce : PkceCodes,
) -> TokenResponse raise Error {
  let body_params = [
    ("grant_type", "authorization_code"),
    ("code", code),
    ("redirect_uri", REDIRECT_URI),
    ("client_id", CLIENT_ID),
    ("code_verifier", pkce.code_verifier),
  ]
  let body = body_params
    .iter()
    .map(fn(p) { "\{url_encode(p.0)}=\{url_encode(p.1)}" })
    .collect()
    .join("&")
  let (response, data) = @http.post("\{OAUTH_ISSUER}/oauth/token", body, headers={
    "Content-Type": "application/x-www-form-urlencoded",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise OAuthError("Token exchange failed: \{response.code} - \{error_text}")
  }
  @json.from_json(data.json())
}

///|
fn url_decode(s : StringView) -> String {
  let buf = StringBuilder::new()
  let chars = s.to_array()
  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '%' && i + 2 < chars.length() {
      let hex1 = chars[i + 1]
      let hex2 = chars[i + 2]
      fn hex_val(c : Char) -> Int? {
        match c {
          '0'..='9' => Some(c.to_int() - '0'.to_int())
          'A'..='F' => Some(c.to_int() - 'A'.to_int() + 10)
          'a'..='f' => Some(c.to_int() - 'a'.to_int() + 10)
          _ => None
        }
      }

      match (hex_val(hex1), hex_val(hex2)) {
        (Some(h1), Some(h2)) => {
          buf.write_char(((h1 << 4) | h2).unsafe_to_char())
          i += 3
          continue
        }
        _ => ()
      }
    } else if c == '+' {
      buf.write_char(' ')
      i += 1
      continue
    }
    buf.write_char(c)
    i += 1
  }
  buf.to_string()
}

///|
fn parse_query_string(query : StringView) -> Map[String, String] {
  let result : Map[String, String] = {}
  if query.is_empty() {
    return result
  }
  for pair in query.split("&") {
    let parts = pair.split("=").to_array()
    if parts.length() == 2 {
      result[url_decode(parts[0])] = url_decode(parts[1])
    }
  }
  result
}

///|
pub async fn start_oauth_flow() -> Credentials raise Error {
  let pkce = generate_pkce()
  let state = generate_state()
  let result : Ref[Credentials?] = Ref::new(None)
  let error_ref : Ref[Error?] = Ref::new(None)
  let done = Ref::new(false)
  let auth_url = build_authorize_url(pkce, state)
  println("\nOpen this URL in your browser to login:\n")
  println("   \{auth_url}\n")
  open_browser(auth_url) catch {
    _ => ()
  }
  let router = @httpx.Router::new()
  router.add_handler(@httpx.Method::Get, "/auth/callback", fn(r, w) {
    let path = r.path
    let parts = path.split("?").to_array()
    let query_string : StringView = if parts.length() > 1 {
      parts[1]
    } else {
      ""
    }
    let query = parse_query_string(query_string)
    let received_state = query.get("state")
    let code = query.get("code")
    let oauth_error = query.get("error")
    if oauth_error is Some(err) {
      w.header().set("Content-Type", "text/html; charset=utf-8")
      w.write_header(400)
      w.write("<h1>Login failed</h1><p>\{err}</p>")
      error_ref.val = Some(OAuthError("OAuth error: \{err}"))
      done.val = true
      return
    }
    if received_state != Some(state) {
      w.header().set("Content-Type", "text/html; charset=utf-8")
      w.write_header(400)
      w.write("<h1>State mismatch</h1>")
      error_ref.val = Some(OAuthError("State mismatch"))
      done.val = true
      return
    }
    guard code is Some(auth_code) else {
      w.header().set("Content-Type", "text/html; charset=utf-8")
      w.write_header(400)
      w.write("<h1>Missing authorization code</h1>")
      error_ref.val = Some(OAuthError("Missing authorization code"))
      done.val = true
      return
    }
    try {
      println("Received authorization code, exchanging for tokens...")
      let tokens = exchange_code_for_tokens(auth_code, pkce)
      let claims = extract_token_claims(tokens.id_token)
      println("Email: \{claims.email}")
      println("Plan: \{claims.chatgptPlanType}")
      let credentials : Credentials = {
        idToken: tokens.id_token,
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        accountId: claims.chatgptAccountId,
      }
      save_credentials(credentials)
      let html =
        #|<!DOCTYPE html>
        #|<html>
        #|<head><title>Login Successful</title></head>
        #|<body style="font-family: system-ui; text-align: center; padding: 50px;">
        #|  <h1>Login Successful!</h1>
        #|  <p>You can close this window now.</p>
        #|</body>
        #|</html>
      w.header().set("Content-Type", "text/html; charset=utf-8")
      w.write_header(200)
      w.write(html)
      result.val = Some(credentials)
      done.val = true
    } catch {
      err => {
        w.header().set("Content-Type", "text/html; charset=utf-8")
        w.write_header(500)
        w.write("<h1>Token exchange failed</h1><p>\{err}</p>")
        error_ref.val = Some(err)
        done.val = true
      }
    }
  })
  let server = @httpx.Server::new("[::1]", CALLBACK_PORT)
  @async.with_task_group(fn(group) {
    group.spawn_bg(fn() { server.serve(router.handler()) }, no_wait=true)
    let timeout_ms : Int64 = 5 * 60 * 1000
    let start_time = @async.now()
    while not(done.val) {
      @async.sleep(100)
      if @async.now() - start_time > timeout_ms {
        server.close()
        raise OAuthError("Login timeout")
      }
    }
    server.close()
  })
  if error_ref.val is Some(err) {
    raise err
  }
  guard result.val is Some(creds) else {
    raise OAuthError("No credentials received")
  }
  creds
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
