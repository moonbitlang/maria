///|
/// A reasoning output item.
struct ResponseReasoningItem {
  /// The unique identifier of the reasoning content.
  id : String
  /// Reasoning summary content.
  summary : Array[ResponseReasoningItemSummary]
  /// Reasoning text content.
  content : Array[ResponseReasoningItemContent]?
  /// The encrypted content of the reasoning item.
  encrypted_content : String?
  /// The status of the item.
  status : ResponseReasoningItemStatus?
}

///|
/// A summary text from the model.
struct ResponseReasoningItemSummary {
  /// A summary of the reasoning output from the model so far.
  text : String
}

///|
/// Reasoning text from the model.
struct ResponseReasoningItemContent {
  /// The reasoning text from the model.
  text : String
}

///|
/// The status of the item.
enum ResponseReasoningItemStatus {
  InProgress
  Completed
  Incomplete
}

///|
pub impl ToJson for ResponseReasoningItemStatus with to_json(
  self : ResponseReasoningItemStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Incomplete => "incomplete"
  }
}

///|
pub impl @json.FromJson for ResponseReasoningItemStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningItemStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseReasoningItemStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "completed" => Completed
    "incomplete" => Incomplete
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseReasoningItemStatus: invalid status '\{status_str}'"),
      )
  }
}

///|
pub impl ToJson for ResponseReasoningItemSummary with to_json(
  self : ResponseReasoningItemSummary,
) -> Json {
  { "type": "summary_text", "text": self.text }
}

///|
pub impl @json.FromJson for ResponseReasoningItemSummary with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningItemSummary raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseReasoningItemSummary::{ text, }
}

///|
pub impl ToJson for ResponseReasoningItemContent with to_json(
  self : ResponseReasoningItemContent,
) -> Json {
  { "type": "reasoning_text", "text": self.text }
}

///|
pub impl @json.FromJson for ResponseReasoningItemContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningItemContent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseReasoningItemContent::{ text, }
}

///|
pub impl ToJson for ResponseReasoningItem with to_json(
  self : ResponseReasoningItem,
) -> Json {
  let obj : Map[String, Json] = {
    "type": "reasoning",
    "id": self.id,
    "summary": self.summary,
  }
  if self.content is Some(content) {
    obj["content"] = content.to_json()
  }
  if self.encrypted_content is Some(encrypted_content) {
    obj["encrypted_content"] = encrypted_content.to_json()
  }
  if self.status is Some(status) {
    obj["status"] = status.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseReasoningItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningItem raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let summary : Array[ResponseReasoningItemSummary] = object.required(
    "summary",
    path~,
  )
  let _ : String = object.required("type", path~)
  let content : Array[ResponseReasoningItemContent]? = object.optional(
    "content",
    path~,
  )
  let encrypted_content : String? = object.optional("encrypted_content", path~)
  let status : ResponseReasoningItemStatus? = object.optional("status", path~)
  ResponseReasoningItem::{ id, summary, content, encrypted_content, status }
}
