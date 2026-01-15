///|
pub struct DeviceCodeResponse {
  device_code : String
  user_code : String
  verification_uri : String
  expires_in : Int
  interval : Int
} derive(Show)

///|
impl @json.FromJson for DeviceCodeResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> DeviceCodeResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "DeviceCodeResponse: expected object"))
  }
  let device_code = match obj.get("device_code") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError(
        (path, "DeviceCodeResponse: missing 'device_code'"),
      )
  }
  let user_code = match obj.get("user_code") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError(
        (path, "DeviceCodeResponse: missing 'user_code'"),
      )
  }
  let verification_uri = match obj.get("verification_uri") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError(
        (path, "DeviceCodeResponse: missing 'verification_uri'"),
      )
  }
  let expires_in = match obj.get("expires_in") {
    Some(Number(n, ..)) => n.to_int()
    _ =>
      raise @json.JsonDecodeError(
        (path, "DeviceCodeResponse: missing 'expires_in'"),
      )
  }
  let interval = match obj.get("interval") {
    Some(Number(n, ..)) => n.to_int()
    _ => 5
  }
  { device_code, user_code, verification_uri, expires_in, interval }
}

///|
struct AccessTokenResponse {
  access_token : String?
  error : String?
} derive(Show)

///|
impl @json.FromJson for AccessTokenResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> AccessTokenResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "AccessTokenResponse: expected object"))
  }
  let access_token = match obj.get("access_token") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let error = match obj.get("error") {
    Some(String(s)) => Some(s)
    _ => None
  }
  { access_token, error }
}

///|
pub struct CopilotTokenResponse {
  token : String
  expires_at : Int64
} derive(Show)

///|
impl @json.FromJson for CopilotTokenResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CopilotTokenResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "CopilotTokenResponse: expected object"))
  }
  let token = match obj.get("token") {
    Some(String(s)) => s
    _ =>
      raise @json.JsonDecodeError(
        (path, "CopilotTokenResponse: missing 'token'"),
      )
  }
  let expires_at = match obj.get("expires_at") {
    Some(Number(n, ..)) => n.to_int64()
    _ =>
      raise @json.JsonDecodeError(
        (path, "CopilotTokenResponse: missing 'expires_at'"),
      )
  }
  { token, expires_at }
}

///|
pub async fn request_device_code() -> DeviceCodeResponse raise Error {
  let body : Json = { "client_id": CLIENT_ID, "scope": "read:user" }
  let (response, data) = @http.post(DEVICE_CODE_URL, body, headers={
    "Accept": "application/json",
    "Content-Type": "application/json",
    "User-Agent": "GitHubCopilotChat/0.35.0",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise CopilotOAuthError(
      "Failed to get device code: \{response.code} - \{error_text}",
    )
  }
  @json.from_json(data.json())
}

///|
pub async fn poll_for_access_token(
  device_code : String,
  interval : Int,
  timeout_seconds : Int,
) -> String raise Error {
  let start_time = @async.now()
  let timeout_ms = timeout_seconds.to_int64() * 1000L
  let poll_interval_ms = interval * 1000
  while @async.now() - start_time < timeout_ms {
    @async.sleep(poll_interval_ms)
    let body : Json = {
      "client_id": CLIENT_ID,
      "device_code": device_code,
      "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
    }
    let (response, data) = @http.post(ACCESS_TOKEN_URL, body, headers={
      "Accept": "application/json",
      "Content-Type": "application/json",
      "User-Agent": "GitHubCopilotChat/0.35.0",
    })
    guard response.code is (200..=299) else { continue }
    let result : AccessTokenResponse = @json.from_json(data.json())
    match (result.access_token, result.error) {
      (Some(token), _) => return token
      (_, Some("authorization_pending")) => continue
      (_, Some("slow_down")) => {
        // Wait extra time if GitHub asks us to slow down
        @async.sleep(5000)
        continue
      }
      (_, Some(err)) => raise CopilotOAuthError("OAuth error: \{err}")
      (None, None) => continue
    }
  }
  raise CopilotOAuthError("Authorization timed out")
}

///|
pub async fn get_copilot_token(
  github_token : String,
) -> CopilotTokenResponse raise Error {
  let (response, data) = @http.get(COPILOT_API_KEY_URL, headers={
    "Authorization": "Bearer \{github_token}",
    "Accept": "application/json",
    "User-Agent": "GitHubCopilotChat/0.32.4",
    "Editor-Version": "vscode/1.105.1",
    "Editor-Plugin-Version": "copilot-chat/0.32.4",
    "Copilot-Integration-Id": "vscode-chat",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise CopilotOAuthError(
      "Failed to get Copilot token: \{response.code} - \{error_text}",
    )
  }
  @json.from_json(data.json())
}

///|
pub async fn start_oauth_flow() -> Credentials raise Error {
  println("\nStarting GitHub Copilot authentication...")
  let device_code_response = request_device_code()
  println("\nPlease visit: \{device_code_response.verification_uri}")
  println("And enter code: \{device_code_response.user_code}\n")
  open_browser(device_code_response.verification_uri) catch {
    _ => ()
  }
  println("Waiting for authorization...")
  let github_token = poll_for_access_token(
    device_code_response.device_code,
    device_code_response.interval,
    device_code_response.expires_in,
  )
  println("GitHub authorization successful!")
  println("Getting Copilot API token...")
  let copilot_token_response = get_copilot_token(github_token)
  let credentials : Credentials = {
    github_token,
    copilot_token: copilot_token_response.token,
    copilot_token_expires_at: copilot_token_response.expires_at,
  }
  save_credentials(credentials)
  println("Copilot authentication successful!")
  credentials
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
