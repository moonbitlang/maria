///|
/// POST /v1/auth/codex/start - Initiates Codex PKCE OAuth flow
async fn Daemon::start_codex_auth(
  self : Daemon,
  _r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  // Generate PKCE codes and state
  let pkce = @codex.generate_pkce()
  let state = @codex.generate_state()

  // Build the redirect URI using daemon's port
  let redirect_uri = "http://localhost:\{self.port}/v1/auth/codex/callback"

  // Build authorization URL
  let auth_url = @codex.build_authorize_url(pkce, state, redirect_uri~)

  // Store pending auth state
  let pending = PendingCodexAuth::{
    pkce,
    state,
    created: self.clock.now(),
  }
  self.pending_codex_auth[state] = pending

  // Return auth URL to client
  let response : StartCodexAuthResponse = { auth_url, state }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.to_json().stringify())
}

///|
/// GET /v1/auth/codex/callback - OAuth callback handler
async fn Daemon::codex_callback(
  self : Daemon,
  r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  // Parse query parameters from the URL
  let path = r.path
  let parts = path.split("?").to_array()
  let query_string : StringView = if parts.length() > 1 {
    parts[1]
  } else {
    ""
  }
  let query = @codex.parse_query_string(query_string)

  // Check for OAuth error
  if query.get("error") is Some(error) {
    let error_description = query.get("error_description").unwrap_or("Unknown error")
    self.events.put(AuthLoginFailed(provider="codex", message=error_description))
    serve_error_page(w, "Login failed: \{error} - \{error_description}")
    return
  }

  // Get code and state
  guard query.get("code") is Some(code) else {
    self.events.put(AuthLoginFailed(provider="codex", message="Missing authorization code"))
    serve_error_page(w, "Missing authorization code")
    return
  }
  guard query.get("state") is Some(state) else {
    self.events.put(AuthLoginFailed(provider="codex", message="Missing state parameter"))
    serve_error_page(w, "Missing state parameter")
    return
  }

  // Look up pending auth by state
  guard self.pending_codex_auth.get(state) is Some(pending) else {
    self.events.put(AuthLoginFailed(provider="codex", message="Invalid or expired state"))
    serve_error_page(w, "Invalid or expired state. Please try logging in again.")
    return
  }

  // Remove the pending state
  self.pending_codex_auth.remove(state)

  // Build redirect URI (must match what was used in authorize URL)
  let redirect_uri = "http://localhost:\{self.port}/v1/auth/codex/callback"

  // Exchange code for tokens
  try {
    let tokens = @codex.exchange_code_for_tokens(code, pending.pkce, redirect_uri~)
    let claims = @codex.extract_token_claims(tokens.id_token)

    // Save credentials
    let credentials : @codex.Credentials = {
      idToken: tokens.id_token,
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      accountId: claims.chatgptAccountId,
    }
    @codex.save_credentials(credentials)

    // Broadcast success event
    self.events.put(AuthLoginCompleted(provider="codex"))
    self.events.put(AuthStatusChanged(provider="codex", authenticated=true))

    // Return success page
    serve_success_page(w, "codex", Some(claims.email))
  } catch {
    error => {
      let msg = error.to_string()
      self.events.put(AuthLoginFailed(provider="codex", message=msg))
      serve_error_page(w, "Token exchange failed: \{msg}")
    }
  }
}

///|
/// POST /v1/auth/codex/logout - Clear Codex credentials
async fn Daemon::logout_codex(
  self : Daemon,
  w : @httpx.ResponseWriter,
) -> Unit {
  @codex.delete_credentials()
  self.events.put(AuthStatusChanged(provider="codex", authenticated=false))

  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write("{\"success\": true}")
}

///|
async fn serve_success_page(
  w : @httpx.ResponseWriter,
  provider : String,
  email : String?,
) -> Unit {
  let email_msg = match email {
    Some(e) => "Logged in as \{e}"
    None => "Login successful"
  }
  let buf = StringBuilder::new()
  buf.write_string("<!DOCTYPE html>\n")
  buf.write_string("<html>\n")
  buf.write_string("<head><title>Login Successful</title></head>\n")
  buf.write_string("<body style=\"font-family: system-ui; text-align: center; padding: 50px;\">\n")
  buf.write_string("  <h1>Login Successful!</h1>\n")
  buf.write_string("  <p>\{email_msg}</p>\n")
  buf.write_string("  <p>You can close this window now.</p>\n")
  buf.write_string("  <script>\n")
  buf.write_string("    if (window.opener) { window.opener.postMessage({type: 'oauth-success', provider: '\{provider}'}, '*'); }\n")
  buf.write_string("  </script>\n")
  buf.write_string("</body>\n")
  buf.write_string("</html>\n")

  w.header().set("Content-Type", "text/html; charset=utf-8")
  w.write_header(200)
  w.write(buf.to_string())
}

///|
async fn serve_error_page(w : @httpx.ResponseWriter, message : String) -> Unit {
  let buf = StringBuilder::new()
  buf.write_string("<!DOCTYPE html>\n")
  buf.write_string("<html>\n")
  buf.write_string("<head><title>Login Failed</title></head>\n")
  buf.write_string("<body style=\"font-family: system-ui; text-align: center; padding: 50px;\">\n")
  buf.write_string("  <h1>Login Failed</h1>\n")
  buf.write_string("  <p>\{message}</p>\n")
  buf.write_string("  <p><a href=\"javascript:window.close()\">Close this window</a></p>\n")
  buf.write_string("</body>\n")
  buf.write_string("</html>\n")

  w.header().set("Content-Type", "text/html; charset=utf-8")
  w.write_header(400)
  w.write(buf.to_string())
}
