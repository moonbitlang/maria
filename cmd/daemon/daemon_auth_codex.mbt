///|
/// OAuth callback port registered with OpenAI
const CODEX_CALLBACK_PORT = 1455

///|
/// POST /v1/auth/codex/start - Initiates Codex PKCE OAuth flow
async fn Daemon::start_codex_auth(
  self : Daemon,
  group~ : @async.TaskGroup[Unit],
  _r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  // Generate PKCE codes and state
  let pkce = @codex.generate_pkce()
  let state = @codex.generate_state()

  // Build authorization URL using the default redirect_uri registered with OpenAI
  // (http://localhost:1455/auth/callback)
  let auth_url = @codex.build_authorize_url(pkce, state)

  // Store pending auth state (keyed by state parameter)
  self.pending_codex_auth[state] = PendingCodexAuth::{ pkce, }

  // Spawn temporary callback server on port 1455 to receive OAuth callback (in background)
  group.spawn_bg(() => self.spawn_codex_callback_server(), no_wait=true)

  // Return auth URL to client
  let response : StartCodexAuthResponse = { auth_url, state }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.to_json().stringify())
}

///|
/// Spawns a temporary HTTP server on port 1455 to handle the OAuth callback
/// from OpenAI. The server shuts down after handling one callback.
async fn Daemon::spawn_codex_callback_server(self : Daemon) -> Unit {
  let done = Ref::new(false)
  let pending_auth = self.pending_codex_auth
  let events = self.events
  let router = @httpx.Router::new()
  router.add_handler(@httpx.Method::Get, "/auth/callback", (r, w) => {
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
      let error_description = query
        .get("error_description")
        .unwrap_or("Unknown error")
      events.put(AuthLoginFailed(provider="codex", message=error_description))
      serve_error_page(w, "Login failed: \{error} - \{error_description}")
      done.val = true
      return
    }

    // Get code and state
    guard query.get("code") is Some(code) else {
      events.put(
        AuthLoginFailed(provider="codex", message="Missing authorization code"),
      )
      serve_error_page(w, "Missing authorization code")
      done.val = true
      return
    }
    guard query.get("state") is Some(state) else {
      events.put(
        AuthLoginFailed(provider="codex", message="Missing state parameter"),
      )
      serve_error_page(w, "Missing state parameter")
      done.val = true
      return
    }
    println("[DEBUG] Received OAuth callback. State: \{state}")

    // Look up pending auth by state
    guard pending_auth.get(state) is Some(pending) else {
      events.put(
        AuthLoginFailed(provider="codex", message="Invalid or expired state"),
      )
      serve_error_page(
        w, "Invalid or expired state. Please try logging in again.",
      )
      done.val = true
      return
    }

    // Remove the pending state
    pending_auth.remove(state)

    // Exchange code for tokens (using default redirect_uri)
    try {
      let tokens = @codex.exchange_code_for_tokens(code, pending.pkce)
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
      events.put(AuthLoginCompleted(provider="codex"))
      events.put(AuthStatusChanged(provider="codex", authenticated=true))

      // Return success page
      serve_success_page(w, "codex", Some(claims.email))
    } catch {
      error => {
        let msg = error.to_string()
        events.put(AuthLoginFailed(provider="codex", message=msg))
        serve_error_page(w, "Token exchange failed: \{msg}")
      }
    }
    done.val = true
  })

  // Start temporary server on the registered callback port
  let server = @httpx.Server::new("[::1]", CODEX_CALLBACK_PORT, reuse_addr=true)
  println(
    "[DEBUG] Started OAuth callback server on port \{CODEX_CALLBACK_PORT}",
  )
  @async.with_task_group(group => {
    group.spawn_bg(() => server.serve(router.handler()), no_wait=true)
    // Wait for callback or timeout after 5 minutes
    @async.with_timeout(300_000, () => {
      while not(done.val) {
        @async.sleep(100)
      }
    }) catch {
      @async.TimeoutError =>
        events.put(AuthLoginFailed(provider="codex", message="Login timeout"))
      _ => ()
    }
  })
  println("[DEBUG] OAuth callback server stopped")
}

///|
/// POST /v1/auth/codex/logout - Clear Codex credentials
async fn Daemon::logout_codex(self : Daemon, w : @httpx.ResponseWriter) -> Unit {
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
  buf.write_string(
    "<body style=\"font-family: system-ui; text-align: center; padding: 50px;\">\n",
  )
  buf.write_string("  <h1>Login Successful!</h1>\n")
  buf.write_string("  <p>\{email_msg}</p>\n")
  buf.write_string("  <p>You can close this window now.</p>\n")
  buf.write_string("  <script>\n")
  buf.write_string(
    "    if (window.opener) { window.opener.postMessage({type: 'oauth-success', provider: '\{provider}'}, '*'); }\n",
  )
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
  buf.write_string(
    "<body style=\"font-family: system-ui; text-align: center; padding: 50px;\">\n",
  )
  buf.write_string("  <h1>Login Failed</h1>\n")
  buf.write_string("  <p>\{message}</p>\n")
  buf.write_string(
    "  <p><a href=\"javascript:window.close()\">Close this window</a></p>\n",
  )
  buf.write_string("</body>\n")
  buf.write_string("</html>\n")
  w.header().set("Content-Type", "text/html; charset=utf-8")
  w.write_header(400)
  w.write(buf.to_string())
}
