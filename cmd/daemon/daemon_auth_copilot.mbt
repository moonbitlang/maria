///|
/// POST /v1/auth/copilot/start - Initiates Copilot device code OAuth flow
async fn Daemon::start_copilot_auth(
  self : Daemon,
  group~ : @async.TaskGroup[Unit],
  _r : @httpx.RequestReader,
  w : @httpx.ResponseWriter,
) -> Unit {
  // Request device code from GitHub
  let device_code_response = @copilot.request_device_code() catch {
    error =>
      raise json_error(500, "DeviceCodeError", {
        "error": { "message": error.to_string() },
      })
  }

  // Spawn background task to poll for token
  let events = self.events
  group.spawn_bg(
    () => {
      try {
        // Poll for access token
        let github_token = @copilot.poll_for_access_token(
          device_code_response.device_code,
          device_code_response.interval,
          device_code_response.expires_in,
        )

        // Get Copilot token
        let copilot_token_response = @copilot.get_copilot_token(github_token)

        // Save credentials
        let credentials : @copilot.Credentials = {
          github_token,
          copilot_token: copilot_token_response.token,
          copilot_token_expires_at: copilot_token_response.expires_at,
        }
        @copilot.save_credentials(credentials)

        // Broadcast success event
        events.put(AuthLoginCompleted(provider="copilot"))
        events.put(AuthStatusChanged(provider="copilot", authenticated=true))
      } catch {
        error =>
          events.put(
            AuthLoginFailed(provider="copilot", message=error.to_string()),
          )
      }
    },
    no_wait=true,
  )

  // Return device code info to client
  let response : StartCopilotAuthResponse = {
    user_code: device_code_response.user_code,
    verification_uri: device_code_response.verification_uri,
    expires_in: device_code_response.expires_in,
    interval: device_code_response.interval,
  }
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write(response.to_json().stringify())
}

///|
/// POST /v1/auth/copilot/logout - Clear Copilot credentials
async fn Daemon::logout_copilot(
  self : Daemon,
  w : @httpx.ResponseWriter,
) -> Unit {
  @copilot.delete_credentials()
  self.events.put(AuthStatusChanged(provider="copilot", authenticated=false))
  w.header().set("Content-Type", "application/json")
  w.write_header(200)
  w.write("{\"success\": true}")
}
