///|
pub async fn refresh_tokens(refresh_token : String) -> TokenResponse raise Error {
  let body : Json = {
    "grant_type": "refresh_token",
    "refresh_token": refresh_token,
    "client_id": CLIENT_ID,
  }
  let (response, data) = @http.post(TOKEN_URL, body, headers={
    "Content-Type": "application/json",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise ClaudeOAuthError(
      "Token refresh failed: \{response.code} - \{error_text}",
    )
  }
  @json.from_json(data.json())
}

///|
pub async fn refresh_and_save_credentials() -> Credentials raise Error {
  let credentials = load_credentials()
  println("Refreshing Claude tokens...")
  let refreshed = refresh_tokens(credentials.refresh_token)
  let now = @async.now() / 1000L
  let updated : Credentials = {
    access_token: refreshed.access_token,
    refresh_token: refreshed.refresh_token,
    expires_at: now + refreshed.expires_in.to_int64(),
  }
  save_credentials(updated)
  println("Claude tokens refreshed")
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
