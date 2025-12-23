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
  let payload = if parse_jwt(token) is Object(obj) {
    obj
  } else {
    abort("Invalid token")
  }
  let authClaims = if payload["https://api.openai.com/auth"] is Object(obj) {
    obj
  } else {
    abort("Invalid auth claims")
  }
  {
    email: if payload.get("email") is Some(String(email)) {
      email
    } else {
      abort("No email found in token claims")
    },
    chatgptAccountId: if authClaims.get("chatgpt_account_id")
      is Some(String(chatgptAccountId)) {
      chatgptAccountId
    } else {
      abort("No chatgpt account id found in auth claims")
    },
    chatgptPlanType: if authClaims.get("chatgpt_plan_type")
      is Some(String(chatgptPlanType)) {
      chatgptPlanType
    } else {
      abort("No chatgpt plan type found in auth claims")
    },
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
