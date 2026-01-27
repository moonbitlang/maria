///|
/// An image generation request made by the model.
struct ResponseOutputItemImageGenerationCall {
  /// The unique ID of the image generation call.
  id : String
  /// The generated image encoded in base64.
  result : String
  /// The status of the image generation call.
  status : ResponseOutputItemImageGenerationCallStatus
}

///|
/// The status of the image generation call.
enum ResponseOutputItemImageGenerationCallStatus {
  InProgress
  Completed
  Generating
  Failed
}

///|
pub impl ToJson for ResponseOutputItemImageGenerationCallStatus with to_json(
  self : ResponseOutputItemImageGenerationCallStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Generating => "generating"
    Failed => "failed"
  }
}

///|
pub impl @json.FromJson for ResponseOutputItemImageGenerationCallStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemImageGenerationCallStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseOutputItemImageGenerationCallStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "completed" => Completed
    "generating" => Generating
    "failed" => Failed
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "ResponseOutputItemImageGenerationCallStatus: invalid status '\{status_str}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseOutputItemImageGenerationCall with to_json(
  self : ResponseOutputItemImageGenerationCall,
) -> Json {
  {
    "type": "image_generation_call",
    "id": self.id,
    "result": self.result,
    "status": self.status,
  }
}

///|
pub impl @json.FromJson for ResponseOutputItemImageGenerationCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemImageGenerationCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let result : String = object.required("result", path~)
  let status : ResponseOutputItemImageGenerationCallStatus = object.required(
    "status",
    path~,
  )
  let _ : String = object.required("type", path~)
  ResponseOutputItemImageGenerationCall::{ id, result, status }
}
