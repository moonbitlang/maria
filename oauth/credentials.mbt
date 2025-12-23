///|
pub struct Credentials {
  idToken : String
  accessToken : String
  refreshToken : String
  accountId : String
} derive(Show, ToJson, FromJson)

///|
pub struct IdTokenClaims {
  email : String
  chatgptAccountId : String
  chatgptPlanType : String
} derive(Show)

///|
priv suberror ParseError String

///|
fn add_base64_padding(s : String) -> String {
  let remainder = s.length() % 4
  if remainder == 0 {
    s
  } else {
    let padding = 4 - remainder
    let mut result = s
    for _ in 0..<padding {
      result = result + "="
    }
    result
  }
}

///|
fn parse_jwt(token : String) -> Json raise Error {
  let parts = token.split(".").to_array()
  if parts.length() != 3 {
    raise ParseError("Invalid JWT format")
  }
  let padded = add_base64_padding(parts[1].to_string())
  let payload = @base64.decode(padded, url_safe=true) catch {
    err => {
      println("ERROR in base64.decode: \{err}")
      println("Input: \{padded}")
      raise ParseError("Base64 decode failed: \{err}")
    }
  }
  let payload_str = @encoding/utf8.decode(payload)
  @json.parse(payload_str) catch {
    err => {
      println("ERROR in @json.parse: \{err}")
      println("Decoded payload: \{payload_str}")
      raise ParseError("JSON parse failed: \{err}")
    }
  }
}

///|
pub fn extract_token_claims(token : String) -> IdTokenClaims raise Error {
  let payload = parse_jwt(token).as_object().unwrap()
  let authClaims = payload["https://api.openai.com/auth"].as_object().unwrap()
  {
    email: payload.get("email").unwrap().as_string().unwrap(),
    chatgptAccountId: authClaims
    .get("chatgpt_account_id")
    .unwrap()
    .as_string()
    .unwrap(),
    chatgptPlanType: authClaims
    .get("chatgpt_plan_type")
    .unwrap()
    .as_string()
    .unwrap(),
  }
}

///|
fn get_credentials_path() -> String {
  let home = @os.home() catch {
    err => {
      println("ERROR in @os.home(): \{err}")
      abort("Failed to get home directory")
    }
  }
  @pathx.join(home, CREDENTIALS_FILE)
}

///|
pub async fn save_credentials(credentials : Credentials) -> Unit {
  let path = get_credentials_path()
  @fsx.write_to_file(path, credentials.to_json().stringify(), create=0o600)
}

///|
pub async fn load_credentials() -> Credentials raise Error {
  let path = get_credentials_path()
  if !@fsx.exists_as_file(path) {
    raise ParseError("Credentials file not found")
  } else {
    let content = @fsx.read_file(path)
    @json.from_json(@json.parse(content))
  }
}
