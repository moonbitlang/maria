///|
/// An error object returned when the model fails to generate a response.
pub struct ResponseError {
  code : ResponseErrorCode
  message : String
}

///|
/// The error code for the response.
pub enum ResponseErrorCode {
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
pub impl ToJson for ResponseErrorCode with to_json(self : ResponseErrorCode) -> Json {
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
pub impl @json.FromJson for ResponseErrorCode with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseErrorCode raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "ResponseErrorCode: expected string"))
  }
  match value {
    "server_error" => ServerError
    "rate_limit_exceeded" => RateLimitExceeded
    "invalid_prompt" => InvalidPrompt
    "vector_store_timeout" => VectorStoreTimeout
    "invalid_image" => InvalidImage
    "invalid_image_format" => InvalidImageFormat
    "invalid_base64_image" => InvalidBase64Image
    "invalid_image_url" => InvalidImageUrl
    "image_too_large" => ImageTooLarge
    "image_too_small" => ImageTooSmall
    "image_parse_error" => ImageParseError
    "image_content_policy_violation" => ImageContentPolicyViolation
    "invalid_image_mode" => InvalidImageMode
    "image_file_too_large" => ImageFileTooLarge
    "unsupported_image_media_type" => UnsupportedImageMediaType
    "empty_image_file" => EmptyImageFile
    "failed_to_download_image" => FailedToDownloadImage
    "image_file_not_found" => ImageFileNotFound
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseErrorCode: invalid value '\{value}'"),
      )
  }
}

///|
pub impl ToJson for ResponseError with to_json(self : ResponseError) -> Json {
  { "code": self.code, "message": self.message }
}

///|
pub impl @json.FromJson for ResponseError with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseError raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let code : ResponseErrorCode = object.required("code", path~)
  let message : String = object.required("message", path~)
  ResponseError::{ code, message }
}
