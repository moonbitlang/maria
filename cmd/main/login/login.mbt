///|
pub async fn login() -> Unit {
  println("Starting Codex OAuth login...")
  let credentials = @oauth.start_oauth_flow()
  println("\nLogin successful!")
  println("Credentials saved to ~/.codex-credentials.json")
  let claims = @oauth.extract_token_claims(credentials.idToken)
  println("Logged in as: \{claims.email}")
}
