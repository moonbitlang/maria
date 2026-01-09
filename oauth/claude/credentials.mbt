///|
pub struct Credentials {
  access_token : String
  refresh_token : String
  expires_at : Int64 // Unix timestamp in seconds
} derive(Show, ToJson, FromJson)

///|
fn get_home() -> String {
  @os.home() catch {
    err => {
      println("ERROR in @os.home(): \{err}")
      abort("Failed to get home directory")
    }
  }
}

///|
fn get_credentials_path() -> String {
  @pathx.join(get_home(), CREDENTIALS_FILE)
}

///|
pub async fn save_credentials(credentials : Credentials) -> Unit {
  let path = get_credentials_path()
  let dir = @pathx.dirname(path)
  @fsx.make_directory(dir, recursive=true, exists_ok=true)
  @fsx.write_to_file(path, credentials.to_json().stringify(), create=0o600)
}

///|
pub async fn load_credentials() -> Credentials raise Error {
  let path = get_credentials_path()
  if not(@fsx.exists_as_file(path)) {
    raise ParseError("Claude credentials file not found")
  }
  let content = @fsx.read_file(path)
  @json.from_json(@json.parse(content))
}

///|
pub fn Credentials::is_token_valid(self : Credentials, now : Int64) -> Bool {
  // Consider token valid if it has more than 60 seconds before expiration
  self.expires_at - 60L > now
}
