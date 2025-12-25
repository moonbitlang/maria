///|
pub async fn refresh_and_save_credentials() -> Credentials raise Error {
  let credentials = load_credentials()
  println("Refreshing Copilot token...")
  let (response, data) = @http.get(COPILOT_API_KEY_URL, headers={
    "Authorization": "Bearer \{credentials.github_token}",
    "Accept": "application/json",
    "User-Agent": "GitHubCopilotChat/0.32.4",
    "Editor-Version": "vscode/1.105.1",
    "Editor-Plugin-Version": "copilot-chat/0.32.4",
    "Copilot-Integration-Id": "vscode-chat",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise CopilotOAuthError(
      "Failed to refresh Copilot token: \{response.code} - \{error_text}",
    )
  }
  let json_data = data.json()
  guard json_data is Object(obj) else {
    raise CopilotOAuthError("Invalid response format")
  }
  let token = match obj.get("token") {
    Some(String(s)) => s
    _ => raise CopilotOAuthError("Missing 'token' in response")
  }
  let expires_at = match obj.get("expires_at") {
    Some(Number(n, ..)) => n.to_int64()
    _ => raise CopilotOAuthError("Missing 'expires_at' in response")
  }
  let updated : Credentials = {
    github_token: credentials.github_token,
    copilot_token: token,
    copilot_token_expires_at: expires_at,
  }
  save_credentials(updated)
  println("Copilot token refreshed")
  updated
}

///|
pub async fn get_valid_credentials() -> Credentials raise Error {
  let credentials = load_credentials()
  let now = @async.now() / 1000L
  if credentials.is_token_valid(now) {
    return credentials
  }
  refresh_and_save_credentials()
}
