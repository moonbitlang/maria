///|
async test "oauth_login" {
  let sandbox_disabled = @os.getenv("CODEX_SANDBOX_NETWORK_DISABLED") catch {
    _ => None
  }
  if sandbox_disabled is Some("1") {
    println("Skipping test: network disabled in sandbox")
    return
  }
  try {
    let creds = @oauth.load_credentials()
    println("Already logged in, skipping OAuth flow")
    println("Account ID: \{creds.accountId}")
    return
  } catch {
    _ => ()
  }
  println("Starting OAuth login flow...")
  let credentials = @oauth.start_oauth_flow()
  println("Login successful!")
  println("Account ID: \{credentials.accountId}")
}

///|
async test "oauth_login_and_chat" {
  let sandbox_disabled = @os.getenv("CODEX_SANDBOX_NETWORK_DISABLED") catch {
    _ => None
  }
  if sandbox_disabled is Some("1") {
    println("Skipping test: network disabled in sandbox")
    return
  }
  let credentials = @oauth.load_credentials() catch {
    _ => {
      println(
        "No credentials found, skipping test (run OAuth login manually first)",
      )
      return
    }
  }
  let claims = @oauth.extract_token_claims(credentials.idToken)
  println("Logged in as: \{claims.email}")
  println("Plan: \{claims.chatgptPlanType}")
  println("\nTesting chat API...")
  let response = @oauth.chat("Say hello in one word")
  println("AI response: \{response}")
  assert_true(response.length() > 0)
}

///|
async test "stream_responses" {
  let sandbox_disabled = @os.getenv("CODEX_SANDBOX_NETWORK_DISABLED") catch {
    _ => None
  }
  if sandbox_disabled is Some("1") {
    println("Skipping test: network disabled in sandbox")
    return
  }
  ignore(
    @oauth.load_credentials() catch {
      _ => {
        println("No credentials, skipping stream test")
        return
      }
    },
  )
  let chunks : Array[String] = []
  let completed = Ref::new(false)
  let error_msg : Ref[String?] = Ref::new(None)
  @oauth.stream_responses(
    @oauth.ResponsesRequest::new(
      model="gpt-4o-mini",
      input=[@oauth.user_message("Count from 1 to 3")],
      instructions="Be concise",
    ),
    @oauth.StreamCallbacks::new(
      on_chunk=fn(chunk) { chunks.push(chunk) },
      on_complete=fn() { completed.val = true },
      on_error=fn(err) { error_msg.val = Some(err.to_string()) },
    ),
  )
  if error_msg.val is Some(msg) {
    fail("Stream error: \{msg}")
  }
  assert_true(completed.val)
  assert_true(chunks.length() > 0)
  let full_response = chunks.iter().fold(init="", fn(acc, c) { acc + c })
  println("Stream response: \{full_response}")
}

///|
async test "call_responses" {
  let sandbox_disabled = @os.getenv("CODEX_SANDBOX_NETWORK_DISABLED") catch {
    _ => None
  }
  if sandbox_disabled is Some("1") {
    println("Skipping test: network disabled in sandbox")
    return
  }
  ignore(
    @oauth.load_credentials() catch {
      _ => {
        println("No credentials, skipping call_responses test")
        return
      }
    },
  )
  let response = @oauth.call_responses(
    @oauth.ResponsesRequest::new(
      model="gpt-4o-mini",
      input=[@oauth.user_message("What is 2+2?")],
      instructions="Answer with just the number",
    ),
  )
  println("Response JSON: \{response}")
  assert_true(response is Object(_))
}

///|
async test "refresh_tokens" {
  let sandbox_disabled = @os.getenv("CODEX_SANDBOX_NETWORK_DISABLED") catch {
    _ => None
  }
  if sandbox_disabled is Some("1") {
    println("Skipping test: network disabled in sandbox")
    return
  }
  ignore(
    @oauth.load_credentials() catch {
      _ => {
        println("No credentials, skipping refresh test")
        return
      }
    },
  )
  println("Testing token refresh...")
  let refreshed = @oauth.refresh_and_save_credentials()
  assert_true(refreshed.accessToken.length() > 0)
  println("Token refreshed successfully")
}

///|
test "build_authorize_url" {
  let pkce = @oauth.PkceCodes::new(
    code_verifier="test_verifier",
    code_challenge="test_challenge",
  )
  let state = "test_state"
  let url = @oauth.build_authorize_url(pkce, state)
  assert_true(url.contains("response_type=code"))
  assert_true(url.contains("code_challenge=test_challenge"))
  assert_true(url.contains("state=test_state"))
}

///|
test "generate_pkce" {
  let pkce = @oauth.generate_pkce()
  assert_true(pkce.code_verifier.length() > 80)
  assert_true(pkce.code_challenge.length() > 40)
}

///|
test "user_message" {
  let msg = @oauth.user_message("hello")
  ignore(msg)
}
