///|
/// A web search tool call.
struct ResponseFunctionWebSearch {
  /// The unique ID of the web search tool call.
  id : String
  /// An object describing the specific action taken in this web search call.
  action : ResponseFunctionWebSearchAction
  /// The status of the web search tool call.
  status : ResponseFunctionWebSearchStatus
}

///|
enum ResponseFunctionWebSearchAction {
  Search(ResponseFunctionWebSearchActionSearch)
  OpenPage(ResponseFunctionWebSearchActionOpenPage)
  Find(ResponseFunctionWebSearchActionFind)
}

///|
/// Action type "search" - Performs a web search query.
struct ResponseFunctionWebSearchActionSearch {
  /// The search query.
  query : String
  /// The sources used in the search.
  sources : Array[ResponseFunctionWebSearchActionSearchSource]
}

///|
/// A source used in the search.
struct ResponseFunctionWebSearchActionSearchSource {
  /// The URL of the source.
  url : String
}

///|
/// Action type "open_page" - Opens a specific URL from search results.
struct ResponseFunctionWebSearchActionOpenPage {
  /// The URL opened by the model.
  url : String
}

///|
/// Action type "find": Searches for a pattern within a loaded page.
struct ResponseFunctionWebSearchActionFind {
  /// The pattern or text to search for within the page.
  pattern : String
  /// The URL of the page searched for the pattern.
  url : String
}

///|
/// The status of the web search tool call.
enum ResponseFunctionWebSearchStatus {
  InProgress
  Searching
  Completed
  Failed
}

///|
pub impl ToJson for ResponseFunctionWebSearchStatus with to_json(
  self : ResponseFunctionWebSearchStatus,
) -> Json {
  match self {
    InProgress => "in_progress"
    Searching => "searching"
    Completed => "completed"
    Failed => "failed"
  }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearchStatus with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearchStatus raise @json.JsonDecodeError {
  guard json is String(status_str) else {
    raise @json.JsonDecodeError(
      (path, "ResponseFunctionWebSearchStatus: expected string"),
    )
  }
  match status_str {
    "in_progress" => InProgress
    "searching" => Searching
    "completed" => Completed
    "failed" => Failed
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "ResponseFunctionWebSearchStatus: invalid status '\{status_str}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseFunctionWebSearchActionSearchSource with to_json(
  self : ResponseFunctionWebSearchActionSearchSource,
) -> Json {
  { "type": "url", "url": self.url }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearchActionSearchSource with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearchActionSearchSource raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let url : String = object.required("url", path~)
  ResponseFunctionWebSearchActionSearchSource::{ url, }
}

///|
pub impl ToJson for ResponseFunctionWebSearchActionSearch with to_json(
  self : ResponseFunctionWebSearchActionSearch,
) -> Json {
  { "type": "search", "query": self.query, "sources": self.sources }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearchActionSearch with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearchActionSearch raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let query : String = object.required("query", path~)
  let sources : Array[ResponseFunctionWebSearchActionSearchSource] = object.required(
    "sources",
    path~,
  )
  let _ : String = object.required("type", path~)
  ResponseFunctionWebSearchActionSearch::{ query, sources }
}

///|
pub impl ToJson for ResponseFunctionWebSearchActionOpenPage with to_json(
  self : ResponseFunctionWebSearchActionOpenPage,
) -> Json {
  { "type": "open_page", "url": self.url }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearchActionOpenPage with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearchActionOpenPage raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let url : String = object.required("url", path~)
  ResponseFunctionWebSearchActionOpenPage::{ url, }
}

///|
pub impl ToJson for ResponseFunctionWebSearchActionFind with to_json(
  self : ResponseFunctionWebSearchActionFind,
) -> Json {
  { "type": "find", "pattern": self.pattern, "url": self.url }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearchActionFind with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearchActionFind raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let pattern : String = object.required("pattern", path~)
  let _ : String = object.required("type", path~)
  let url : String = object.required("url", path~)
  ResponseFunctionWebSearchActionFind::{ pattern, url }
}

///|
pub impl ToJson for ResponseFunctionWebSearchAction with to_json(
  self : ResponseFunctionWebSearchAction,
) -> Json {
  match self {
    Search(action) => action.to_json()
    OpenPage(action) => action.to_json()
    Find(action) => action.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearchAction with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearchAction raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "search" => Search(@json.from_json(json, path~))
    "open_page" => OpenPage(@json.from_json(json, path~))
    "find" => Find(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseFunctionWebSearchAction: invalid type '\{type_str}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseFunctionWebSearch with to_json(
  self : ResponseFunctionWebSearch,
) -> Json {
  {
    "type": "web_search_call",
    "id": self.id,
    "action": self.action,
    "status": self.status,
  }
}

///|
pub impl @json.FromJson for ResponseFunctionWebSearch with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionWebSearch raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let action : ResponseFunctionWebSearchAction = object.required(
    "action",
    path~,
  )
  let status : ResponseFunctionWebSearchStatus = object.required(
    "status",
    path~,
  )
  let _ : String = object.required("type", path~)
  ResponseFunctionWebSearch::{ id, action, status }
}
