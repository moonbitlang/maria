///|
pub struct PkceCodes {
  code_verifier : String
  code_challenge : String
} derive(Show)

///|
pub fn PkceCodes::new(
  code_verifier~ : String,
  code_challenge~ : String,
) -> PkceCodes {
  { code_verifier, code_challenge }
}

///|
fn gen_byte(randomer : @random.Rand) -> Byte {
  randomer.int().to_byte()
}

///|
fn generate_random_bytes(length : Int) -> Bytes {
  let randomer = @rand.chacha8() catch {
    _ => abort("Failed to create random generator")
  }
  let bytes : FixedArray[Byte] = FixedArray::make(length, 0)
  for i in 0..<length {
    bytes[i] = gen_byte(randomer)
  }
  Bytes::from_array(bytes)
}

///|
fn strip_padding(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if c != '=' {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
pub fn generate_pkce() -> PkceCodes {
  let bytes = generate_random_bytes(64)
  let code_verifier = strip_padding(@base64.encode(bytes, url_safe=true))
  let code_challenge = strip_padding(
    @base64.encode(
      Bytes::from_array(@crypto.sha256(@encoding/utf8.encode(code_verifier))),
      url_safe=true,
    ),
  )
  { code_verifier, code_challenge }
}

///|
test "generate_pkce produces valid codes" {
  let pkce = generate_pkce()
  assert_true(pkce.code_verifier.length() > 80)
  assert_true(pkce.code_challenge.length() > 40)
  assert_true(pkce.code_verifier != pkce.code_challenge)
}
