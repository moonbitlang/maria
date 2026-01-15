///|
/// Auth status for a single provider
priv struct ProviderAuthStatus {
  authenticated : Bool
  email : String?
  plan : String?
} derive(ToJson)

///|
/// Combined auth status for all providers
priv struct AllAuthStatus {
  codex : ProviderAuthStatus
  copilot : ProviderAuthStatus
} derive(ToJson)

///|
/// Response for starting Codex OAuth flow
priv struct StartCodexAuthResponse {
  auth_url : String
  state : String
} derive(ToJson)

///|
/// Response for starting Copilot OAuth flow
priv struct StartCopilotAuthResponse {
  user_code : String
  verification_uri : String
  expires_in : Int
  interval : Int
} derive(ToJson)

///|
/// GET /v1/auth/status - Returns auth status for all providers
async fn Daemon::get_auth_status(
  self : Daemon,
  w : @httpx.ResponseWriter,
) -> Unit {
  let codex_status = self.get_codex_auth_status()
  let copilot_status = self.get_copilot_auth_status()
  let status : AllAuthStatus = { codex: codex_status, copilot: copilot_status }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(status.to_json().stringify())
}

///|
/// Get Codex auth status by checking credentials and extracting user info
async fn Daemon::get_codex_auth_status(self : Daemon) -> ProviderAuthStatus {
  ignore(self)
  if not(@codex.credentials_exist()) {
    return { authenticated: false, email: None, plan: None }
  }
  try {
    let credentials = @codex.load_credentials()
    let claims = @codex.extract_token_claims(credentials.idToken)
    {
      authenticated: true,
      email: Some(claims.email),
      plan: Some(claims.chatgptPlanType),
    }
  } catch {
    _ => { authenticated: false, email: None, plan: None }
  }
}

///|
/// Get Copilot auth status by checking credentials
async fn Daemon::get_copilot_auth_status(self : Daemon) -> ProviderAuthStatus {
  ignore(self)
  if not(@copilot.credentials_exist()) {
    return { authenticated: false, email: None, plan: None }
  }
  // Copilot doesn't provide email/plan info in the token
  { authenticated: true, email: None, plan: None }
}
