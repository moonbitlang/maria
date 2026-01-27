///|
/// The results of a file search tool call.
struct ResponseFileSearchToolCall {
  /// The unique ID of the file search tool call.
  id : String
  /// The queries used to search for files.
  queries : Array[String]
  /// The status of the file search tool call.
  status : ResponseFileSearchToolCallStatus
  /// The results of the file search tool call.
  results : Array[ResponseFileSearchToolCallResult]?
}

///|
/// The status of the file search tool call.
enum ResponseFileSearchToolCallStatus {
  InProgress
  Searching
  Completed
  Incomplete
  Failed
}

///|
struct ResponseFileSearchToolCallResult {
  /// Additional attributes associated with the file.
  attributes : Map[String, ResponseFileSearchToolCallResultAttribute]?
  /// The unique ID of the file.
  file_id : String
  /// The name of the file.
  filename : String
  /// The relevance score of the file - a value between 0 and 1.
  score : Double
  /// The text that was retrieved from the file.
  text : String
}

///|
enum ResponseFileSearchToolCallResultAttribute {
  String(String)
  Float(Double)
  Bool(Bool)
}

///|
pub impl ToJson for ResponseFileSearchToolCallStatus with to_json(
  self : ResponseFileSearchToolCallStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Searching => "searching"
    Completed => "completed"
    Incomplete => "incomplete"
    Failed => "failed"
  }
}

///|
pub impl @json.FromJson for ResponseFileSearchToolCallStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchToolCallStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseFileSearchToolCallStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "searching" => Searching
    "completed" => Completed
    "incomplete" => Incomplete
    "failed" => Failed
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "ResponseFileSearchToolCallStatus: invalid status '\{status_str}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseFileSearchToolCallResultAttribute with to_json(
  self : ResponseFileSearchToolCallResultAttribute,
) -> Json {
  match self {
    String(value) => value.to_json()
    Float(value) => value.to_json()
    Bool(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseFileSearchToolCallResultAttribute with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchToolCallResultAttribute raise @json.JsonDecodeError {
  match json {
    String(value) => String(value)
    Number(value, repr=_) => Float(value)
    True => Bool(true)
    False => Bool(false)
    _ =>
      raise @json.JsonDecodeError(
        (path, "ResponseFileSearchToolCallResultAttribute: invalid value"),
      )
  }
}

///|
pub impl ToJson for ResponseFileSearchToolCallResult with to_json(
  self : ResponseFileSearchToolCallResult,
) -> Json {
  let obj : Map[String, Json] = {
    "file_id": self.file_id,
    "filename": self.filename,
    "score": self.score,
    "text": self.text,
  }
  if self.attributes is Some(attributes) {
    let attributes_obj : Map[String, Json] = {}
    for entry in attributes.iter() {
      let (key, value) = entry
      attributes_obj[key] = value.to_json()
    }
    obj["attributes"] = Json::object(attributes_obj)
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseFileSearchToolCallResult with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchToolCallResult raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let file_id : String = object.required("file_id", path~)
  let filename : String = object.required("filename", path~)
  let score : Double = object.required("score", path~)
  let text : String = object.required("text", path~)
  let attributes_json : Json? = object.optional("attributes", path~)
  let attributes = match attributes_json {
    None => None
    Some(Object(attr_obj)) => {
      let attrs : Map[String, ResponseFileSearchToolCallResultAttribute] = {}
      for entry in attr_obj.iter() {
        let (key, value_json) = entry
        attrs[key] = @json.from_json(
          value_json,
          path=path.add_key("attributes").add_key(key),
        )
      }
      Some(attrs)
    }
    Some(_) =>
      raise @json.JsonDecodeError(
        (
          path.add_key("attributes"),
          "ResponseFileSearchToolCallResult: expected object for 'attributes'",
        ),
      )
  }
  ResponseFileSearchToolCallResult::{
    attributes,
    file_id,
    filename,
    score,
    text,
  }
}

///|
pub impl ToJson for ResponseFileSearchToolCall with to_json(
  self : ResponseFileSearchToolCall,
) -> Json {
  let obj : Map[String, Json] = {
    "type": "file_search_call",
    "id": self.id,
    "queries": self.queries,
    "status": self.status,
  }
  if self.results is Some(results) {
    obj["results"] = results.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseFileSearchToolCall with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchToolCall raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let queries : Array[String] = object.required("queries", path~)
  let status : ResponseFileSearchToolCallStatus = object.required(
    "status",
    path~,
  )
  let _ : String = object.required("type", path~)
  let results : Array[ResponseFileSearchToolCallResult]? = object.optional(
    "results",
    path~,
  )
  ResponseFileSearchToolCall::{ id, queries, status, results }
}
