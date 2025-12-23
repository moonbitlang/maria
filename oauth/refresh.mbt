///|
struct RefreshResponse {
  id_token : String?
  access_token : String?
  refresh_token : String?
} derive(Show)

///|
impl @json.FromJson for RefreshResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> RefreshResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "RefreshResponse: expected object"))
  }
  let id_token : String? = match obj.get("id_token") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let access_token : String? = match obj.get("access_token") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let refresh_token : String? = match obj.get("refresh_token") {
    Some(String(s)) => Some(s)
    _ => None
  }
  { id_token, access_token, refresh_token }
}

///|
pub async fn refresh_tokens(
  refresh_token : String,
) -> RefreshResponse raise Error {
  let body : Json = {
    "client_id": CLIENT_ID,
    "grant_type": "refresh_token",
    "refresh_token": refresh_token,
    "scope": "openid profile email",
  }
  let (response, data) = @http.post(REFRESH_TOKEN_URL, body, headers={
    "Content-Type": "application/json",
  })
  guard response.code is (200..=299) else {
    let error_text = data.text()
    raise ApiError(
      code=response.code,
      message="Token refresh failed: \{error_text}",
    )
  }
  @json.from_json(data.json())
}

///|
pub async fn refresh_and_save_credentials() -> Credentials raise Error {
  let credentials = load_credentials()
  println("Refreshing tokens...")
  let refreshed = refresh_tokens(credentials.refreshToken)
  let updated : Credentials = {
    idToken: refreshed.id_token.unwrap_or(credentials.idToken),
    accessToken: refreshed.access_token.unwrap_or(credentials.accessToken),
    refreshToken: refreshed.refresh_token.unwrap_or(credentials.refreshToken),
    accountId: credentials.accountId,
  }
  let final_credentials = if refreshed.id_token is Some(new_id_token) {
    let claims = extract_token_claims(new_id_token)
    { ..updated, accountId: claims.chatgptAccountId }
  } else {
    updated
  }
  save_credentials(final_credentials)
  println("Tokens refreshed")
  final_credentials
}
