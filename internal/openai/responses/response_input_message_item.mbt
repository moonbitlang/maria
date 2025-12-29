///|
/// A message input item returned by the API.
pub struct ResponseInputMessageItem {
  id : String
  content : ResponseInputMessageContentList
  role : ResponseInputMessageItemRole
  status : ResponseInputMessageItemStatus?
  type_ : String?
}

///|
pub enum ResponseInputMessageItemRole {
  User
  System
  Developer
}

///|
pub enum ResponseInputMessageItemStatus {
  InProgress
  Completed
  Incomplete
}

///|
pub impl ToJson for ResponseInputMessageItemRole with to_json(
  self : ResponseInputMessageItemRole,
) -> Json {
  match self {
    User => "user"
    System => "system"
    Developer => "developer"
  }
}

///|
pub impl @json.FromJson for ResponseInputMessageItemRole with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputMessageItemRole raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ResponseInputMessageItemRole: expected string"),
    )
  }
  match value {
    "user" => User
    "system" => System
    "developer" => Developer
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseInputMessageItemRole: invalid value '\{value}'"),
      )
  }
}

///|
pub impl ToJson for ResponseInputMessageItemStatus with to_json(
  self : ResponseInputMessageItemStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Completed => "completed"
    Incomplete => "incomplete"
  }
}

///|
pub impl @json.FromJson for ResponseInputMessageItemStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputMessageItemStatus raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ResponseInputMessageItemStatus: expected string"),
    )
  }
  match value {
    "in_progress" => InProgress
    "completed" => Completed
    "incomplete" => Incomplete
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseInputMessageItemStatus: invalid value '\{value}'"),
      )
  }
}

///|
pub impl ToJson for ResponseInputMessageItem with to_json(
  self : ResponseInputMessageItem,
) -> Json {
  let obj : Map[String, Json] = {
    "id": self.id,
    "content": self.content,
    "role": self.role,
  }
  if self.status is Some(status) {
    obj["status"] = status.to_json()
  }
  if self.type_ is Some(type_) {
    obj["type"] = type_.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseInputMessageItem with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInputMessageItem raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let content : ResponseInputMessageContentList = object.required(
    "content",
    path~,
  )
  let role : ResponseInputMessageItemRole = object.required("role", path~)
  let status : ResponseInputMessageItemStatus? = object.optional(
    "status",
    path~,
  )
  let type_ : String? = object.optional("type", path~)
  ResponseInputMessageItem::{ id, content, role, status, type_ }
}
