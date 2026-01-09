///|
enum ResponsesErrorCode {
  ServerError
  RateLimitExceeded
  InvalidPrompt
  VectorStoreTimeout
  InvalidImage
  InvalidImageFormat
  InvalidBase64Image
  InvalidImageUrl
  ImageTooLarge
  ImageTooSmall
  ImageParseError
  ImageContentPolicyViolation
  InvalidImageMode
  ImageFileTooLarge
  UnsupportedImageMediaType
  EmptyImageFile
  FailedToDownloadImage
  ImageFileNotFound
}

///|
pub impl ToJson for ResponsesErrorCode with to_json(
  self : ResponsesErrorCode,
) -> Json {
  match self {
    ServerError => "server_error"
    RateLimitExceeded => "rate_limit_exceeded"
    InvalidPrompt => "invalid_prompt"
    VectorStoreTimeout => "vector_store_timeout"
    InvalidImage => "invalid_image"
    InvalidImageFormat => "invalid_image_format"
    InvalidBase64Image => "invalid_base64_image"
    InvalidImageUrl => "invalid_image_url"
    ImageTooLarge => "image_too_large"
    ImageTooSmall => "image_too_small"
    ImageParseError => "image_parse_error"
    ImageContentPolicyViolation => "image_content_policy_violation"
    InvalidImageMode => "invalid_image_mode"
    ImageFileTooLarge => "image_file_too_large"
    UnsupportedImageMediaType => "unsupported_image_media_type"
    EmptyImageFile => "empty_image_file"
    FailedToDownloadImage => "failed_to_download_image"
    ImageFileNotFound => "image_file_not_found"
  }
}

///|
pub impl @json.FromJson for ResponsesErrorCode with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponsesErrorCode raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ResponsesErrorCode::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "server_error" => ResponsesErrorCode::ServerError
    "rate_limit_exceeded" => ResponsesErrorCode::RateLimitExceeded
    "invalid_prompt" => ResponsesErrorCode::InvalidPrompt
    "vector_store_timeout" => ResponsesErrorCode::VectorStoreTimeout
    "invalid_image" => ResponsesErrorCode::InvalidImage
    "invalid_image_format" => ResponsesErrorCode::InvalidImageFormat
    "invalid_base64_image" => ResponsesErrorCode::InvalidBase64Image
    "invalid_image_url" => ResponsesErrorCode::InvalidImageUrl
    "image_too_large" => ResponsesErrorCode::ImageTooLarge
    "image_too_small" => ResponsesErrorCode::ImageTooSmall
    "image_parse_error" => ResponsesErrorCode::ImageParseError
    "image_content_policy_violation" =>
      ResponsesErrorCode::ImageContentPolicyViolation
    "invalid_image_mode" => ResponsesErrorCode::InvalidImageMode
    "image_file_too_large" => ResponsesErrorCode::ImageFileTooLarge
    "unsupported_image_media_type" =>
      ResponsesErrorCode::UnsupportedImageMediaType
    "empty_image_file" => ResponsesErrorCode::EmptyImageFile
    "failed_to_download_image" => ResponsesErrorCode::FailedToDownloadImage
    "image_file_not_found" => ResponsesErrorCode::ImageFileNotFound
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}

///|
pub struct ResponsesErrorField {
  code : ResponsesErrorCode
  message : String
}

///|
pub impl ToJson for ResponsesErrorField with to_json(
  self : ResponsesErrorField,
) -> Json {
  let object : Map[String, Json] = {
    "code": self.code.to_json(),
    "message": self.message.to_json(),
  }
  Json::object(object)
}

///|
pub impl @json.FromJson for ResponsesErrorField with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponsesErrorField raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ResponsesErrorField::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let code : ResponsesErrorCode = match object.get("code") {
    Some(v) => @json.from_json(v, path=path.add_key("code"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("code"), "\{func_name}: missing field code"),
      )
  }
  let message : String = match object.get("message") {
    Some(v) => @json.from_json(v, path=path.add_key("message"))
    None =>
      raise @json.JsonDecodeError(
        (path.add_key("message"), "\{func_name}: missing field message"),
      )
  }
  ResponsesErrorField::{ code, message }
}
