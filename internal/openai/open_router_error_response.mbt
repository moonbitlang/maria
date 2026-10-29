///|
pub struct OpenRouterErrorResponse {
  code : Int32
  message : String
  metadata : Json
} derive(ToJson)

///|
pub impl @json.FromJson for OpenRouterErrorResponse with fn from_json(
  json : Json,
  json_path : @json.JsonPath,
) -> OpenRouterErrorResponse {
  guard json is Object(json) else {
    raise @json.JsonDecodeError((json_path, "Expected an object"))
  }
  guard json.get("code") is Some(Number(code, ..)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'code' field"))
  }
  guard json.get("message") is Some(String(message)) else {
    raise @json.JsonDecodeError((json_path, "Missing 'message' field"))
  }
  guard json.get("metadata") is Some(metadata) else {
    raise @json.JsonDecodeError((json_path, "Missing 'metadata' field"))
  }
  OpenRouterErrorResponse::{ code: code.to_int(), message, metadata, }
}

///|
pub extend OpenRouterErrorResponse with ToJson::{to_json}

///|
pub extend OpenRouterErrorResponse with @moonbitlang/core/json.FromJson::{
  from_json,
}
