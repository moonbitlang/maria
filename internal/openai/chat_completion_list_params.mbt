///|
pub(all) enum ChatCompletionListParamsOrder {
  Asc
  Desc
}

///|
pub impl ToJson for ChatCompletionListParamsOrder with to_json(
  self : ChatCompletionListParamsOrder,
) -> Json {
  match self {
    Asc => "asc"
    Desc => "desc"
  }
}

///|
pub struct ChatCompletionListParams {
  after : String?
  limit : Int?
  model : String?
  metadata : Map[String, String]?
  order : ChatCompletionListParamsOrder?
}

///|
pub fn ChatCompletionListParams::empty() -> ChatCompletionListParams {
  { after: None, limit: None, model: None, metadata: None, order: None }
}

///|
pub fn ChatCompletionListParams::new(
  after? : String,
  limit? : Int,
  model? : String,
  metadata? : Map[String, String],
  order? : ChatCompletionListParamsOrder,
) -> ChatCompletionListParams {
  { after, limit, model, metadata, order }
}

///|
fn ChatCompletionListParams::to_query_string(
  self : ChatCompletionListParams,
) -> String {
  let parts : Array[String] = []
  if self.after is Some(value) {
    parts.push("after=\{@client.encode_query_component(value)}")
  }
  if self.limit is Some(value) {
    parts.push("limit=\{@client.encode_query_component(value.to_string())}")
  }
  if self.model is Some(value) {
    parts.push("model=\{@client.encode_query_component(value)}")
  }
  if self.metadata is Some(metadata) {
    for k, v in metadata {
      parts.push(
        "metadata[\{@client.encode_query_component(k)}]=\{@client.encode_query_component(v)}",
      )
    }
  }
  if self.order is Some(value) {
    let order_str = match value {
      Asc => "asc"
      Desc => "desc"
    }
    parts.push("order=\{@client.encode_query_component(order_str)}")
  }
  if parts.is_empty() {
    ""
  } else {
    let joined = parts.join("&")
    "?\{joined}"
  }
}

///|
pub struct ChatCompletionListResponse {
  data : Array[ChatCompletion]
  has_more : Bool
  first_id : String?
  last_id : String?
  object_ : String
}

///|
pub impl @json.FromJson for ChatCompletionListResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatCompletionListResponse raise @json.JsonDecodeError {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionListResponse: expected object"),
    )
  }
  guard obj.get("data") is Some(data) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionListResponse: missing 'data'"),
    )
  }
  let data : Array[ChatCompletion] = @json.from_json(
    data,
    path=path.add_key("data"),
  )
  guard obj.get("has_more") is Some(has_more) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionListResponse: missing 'has_more'"),
    )
  }
  let has_more : Bool = match has_more {
    True => true
    False => false
    _ =>
      raise @json.JsonDecodeError(
        (path, "ChatCompletionListResponse: 'has_more' must be boolean"),
      )
  }
  let first_id = match obj.get("first_id") {
    Some(String(v)) => Some(v)
    Some(Null) | None => None
    _ =>
      raise @json.JsonDecodeError(
        (path, "ChatCompletionListResponse: 'first_id' must be string"),
      )
  }
  let last_id = match obj.get("last_id") {
    Some(String(v)) => Some(v)
    Some(Null) | None => None
    _ =>
      raise @json.JsonDecodeError(
        (path, "ChatCompletionListResponse: 'last_id' must be string"),
      )
  }
  guard obj.get("object") is Some(String(object_)) else {
    raise @json.JsonDecodeError(
      (path, "ChatCompletionListResponse: missing 'object'"),
    )
  }
  ChatCompletionListResponse::{ data, has_more, first_id, last_id, object_ }
}
