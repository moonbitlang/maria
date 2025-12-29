///|
pub struct ChatCompletionDeleted {
  id : String
  deleted : Bool
  object_ : String
}

///|
pub impl ToJson for ChatCompletionDeleted with to_json(
  self : ChatCompletionDeleted,
) -> Json {
  {
    "id": self.id.to_json(),
    "deleted": self.deleted.to_json(),
    "object": self.object_.to_json(),
  }
}

///|
pub impl @json.FromJson for ChatCompletionDeleted with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatCompletionDeleted raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionDeleted: expected object"),
    )
  }
  guard obj.get("id") is Some(String(id)) else {
    raise @json.JsonDecodeError((path, "ChatCompletionDeleted: missing 'id'"))
  }
  guard obj.get("deleted") is Some(deleted) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionDeleted: missing 'deleted'"),
    )
  }
  let deleted : Bool = match deleted {
    True => true
    False => false
    _ =>
      raise @json.JsonDecodeError(
        (path, "ChatCompletionDeleted: 'deleted' must be boolean"),
      )
  }
  guard obj.get("object") is Some(String(object_)) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionDeleted: missing 'object'"),
    )
  }
  ChatCompletionDeleted::{ id, deleted, object_ }
}
