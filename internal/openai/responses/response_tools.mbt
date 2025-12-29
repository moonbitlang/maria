///|
/// A function tool definition.
pub struct FunctionTool {
  name : String
  parameters : Map[String, Json]
  strict : Bool
  description : String?
}

///|
pub impl ToJson for FunctionTool with to_json(self : FunctionTool) -> Json {
  let obj : Map[String, Json] = {
    "name": self.name,
    "parameters": self.parameters,
    "strict": self.strict.to_json(),
    "type": "function",
  }
  if self.description is Some(description) {
    obj["description"] = description.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for FunctionTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FunctionTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let parameters : Map[String, Json] = object.required("parameters", path~)
  let strict : Bool = object.required("strict", path~)
  let _ : String = object.required("type", path~)
  let description : String? = object.optional("description", path~)
  FunctionTool::{ name, parameters, strict, description }
}

///|
/// File search tool definition.
pub struct FileSearchTool {
  vector_store_ids : Array[String]
  filters : FileSearchToolFilters?
  max_num_results : Int64?
  ranking_options : FileSearchToolRankingOptions?
}

///|
pub enum FileSearchToolFilters {
  Comparison(@shared.ComparisonFilter)
  Compound(@shared.CompoundFilter)
}

///|
pub impl ToJson for FileSearchToolFilters with to_json(
  self : FileSearchToolFilters,
) -> Json {
  match self {
    Comparison(value) => value.to_json()
    Compound(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for FileSearchToolFilters with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FileSearchToolFilters raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  if object.get("filters") is Some(_) {
    Compound(@json.from_json(json, path~))
  } else {
    Comparison(@json.from_json(json, path~))
  }
}

///|
/// Ranking options for file search.
pub struct FileSearchToolRankingOptions {
  hybrid_search : FileSearchToolRankingOptionsHybridSearch?
  ranker : String?
  score_threshold : Double?
}

///|
pub struct FileSearchToolRankingOptionsHybridSearch {
  embedding_weight : Double
  text_weight : Double
}

///|
pub impl ToJson for FileSearchToolRankingOptionsHybridSearch with to_json(
  self : FileSearchToolRankingOptionsHybridSearch,
) -> Json {
  { "embedding_weight": self.embedding_weight, "text_weight": self.text_weight }
}

///|
pub impl @json.FromJson for FileSearchToolRankingOptionsHybridSearch with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FileSearchToolRankingOptionsHybridSearch raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let embedding_weight : Double = object.required("embedding_weight", path~)
  let text_weight : Double = object.required("text_weight", path~)
  FileSearchToolRankingOptionsHybridSearch::{ embedding_weight, text_weight }
}

///|
pub impl ToJson for FileSearchToolRankingOptions with to_json(
  self : FileSearchToolRankingOptions,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.hybrid_search is Some(hybrid_search) {
    obj["hybrid_search"] = hybrid_search.to_json()
  }
  if self.ranker is Some(ranker) {
    obj["ranker"] = ranker.to_json()
  }
  if self.score_threshold is Some(score_threshold) {
    obj["score_threshold"] = score_threshold.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for FileSearchToolRankingOptions with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FileSearchToolRankingOptions raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let hybrid_search : FileSearchToolRankingOptionsHybridSearch? = object.optional(
    "hybrid_search",
    path~,
  )
  let ranker : String? = object.optional("ranker", path~)
  let score_threshold : Double? = object.optional("score_threshold", path~)
  FileSearchToolRankingOptions::{ hybrid_search, ranker, score_threshold }
}

///|
pub impl ToJson for FileSearchTool with to_json(self : FileSearchTool) -> Json {
  let obj : Map[String, Json] = {
    "type": "file_search",
    "vector_store_ids": self.vector_store_ids,
  }
  if self.filters is Some(filters) {
    obj["filters"] = filters.to_json()
  }
  if self.max_num_results is Some(max_num_results) {
    obj["max_num_results"] = max_num_results.to_json()
  }
  if self.ranking_options is Some(ranking_options) {
    obj["ranking_options"] = ranking_options.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for FileSearchTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FileSearchTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let vector_store_ids : Array[String] = object.required(
    "vector_store_ids",
    path~,
  )
  let filters : FileSearchToolFilters? = object.optional("filters", path~)
  let max_num_results : Int64? = object.optional("max_num_results", path~)
  let ranking_options : FileSearchToolRankingOptions? = object.optional(
    "ranking_options",
    path~,
  )
  FileSearchTool::{
    vector_store_ids,
    filters,
    max_num_results,
    ranking_options,
  }
}

///|
/// Computer tool definition.
pub struct ComputerTool {
  display_height : Int64
  display_width : Int64
  environment : ComputerToolEnvironment
}

///|
pub enum ComputerToolEnvironment {
  Windows
  Mac
  Linux
  Ubuntu
  Browser
}

///|
pub impl ToJson for ComputerToolEnvironment with to_json(
  self : ComputerToolEnvironment,
) -> Json {
  match self {
    Windows => "windows"
    Mac => "mac"
    Linux => "linux"
    Ubuntu => "ubuntu"
    Browser => "browser"
  }
}

///|
pub impl @json.FromJson for ComputerToolEnvironment with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ComputerToolEnvironment raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "ComputerToolEnvironment: expected string"),
    )
  }
  match value {
    "windows" => Windows
    "mac" => Mac
    "linux" => Linux
    "ubuntu" => Ubuntu
    "browser" => Browser
    _ =>
      raise @json.JsonDecodeError(
        (path, "ComputerToolEnvironment: invalid value '\{value}'"),
      )
  }
}

///|
pub impl ToJson for ComputerTool with to_json(self : ComputerTool) -> Json {
  {
    "display_height": self.display_height,
    "display_width": self.display_width,
    "environment": self.environment,
    "type": "computer_use_preview",
  }
}

///|
pub impl @json.FromJson for ComputerTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ComputerTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let display_height = object.required_int64("display_height", path~)
  let display_width = object.required_int64("display_width", path~)
  let environment : ComputerToolEnvironment = object.required(
    "environment",
    path~,
  )
  let _ : String = object.required("type", path~)
  ComputerTool::{ display_height, display_width, environment }
}

///|
/// Web search tool definition.
pub struct WebSearchTool {
  type_ : WebSearchToolType
  filters : WebSearchToolFilters?
  search_context_size : WebSearchToolSearchContextSize?
  user_location : WebSearchToolUserLocation?
}

///|
pub enum WebSearchToolType {
  WebSearch
  WebSearch2025_08_26
}

///|
pub impl ToJson for WebSearchToolType with to_json(self : WebSearchToolType) -> Json {
  match self {
    WebSearch => "web_search"
    WebSearch2025_08_26 => "web_search_2025_08_26"
  }
}

///|
pub impl @json.FromJson for WebSearchToolType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchToolType raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError((path, "WebSearchToolType: expected string"))
  }
  match value {
    "web_search" => WebSearch
    "web_search_2025_08_26" => WebSearch2025_08_26
    _ =>
      raise @json.JsonDecodeError(
        (path, "WebSearchToolType: invalid value '\{value}'"),
      )
  }
}

///|
pub struct WebSearchToolFilters {
  allowed_domains : Array[String]?
}

///|
pub impl ToJson for WebSearchToolFilters with to_json(
  self : WebSearchToolFilters,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.allowed_domains is Some(allowed_domains) {
    obj["allowed_domains"] = allowed_domains.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for WebSearchToolFilters with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchToolFilters raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let allowed_domains : Array[String]? = object.optional(
    "allowed_domains",
    path~,
  )
  WebSearchToolFilters::{ allowed_domains, }
}

///|
pub enum WebSearchToolSearchContextSize {
  Low
  Medium
  High
}

///|
pub impl ToJson for WebSearchToolSearchContextSize with to_json(
  self : WebSearchToolSearchContextSize,
) -> Json {
  match self {
    Low => "low"
    Medium => "medium"
    High => "high"
  }
}

///|
pub impl @json.FromJson for WebSearchToolSearchContextSize with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchToolSearchContextSize raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "WebSearchToolSearchContextSize: expected string"),
    )
  }
  match value {
    "low" => Low
    "medium" => Medium
    "high" => High
    _ =>
      raise @json.JsonDecodeError(
        (path, "WebSearchToolSearchContextSize: invalid value '\{value}'"),
      )
  }
}

///|
pub struct WebSearchToolUserLocation {
  city : String?
  country : String?
  region : String?
  timezone : String?
  type_ : String?
}

///|
pub impl ToJson for WebSearchToolUserLocation with to_json(
  self : WebSearchToolUserLocation,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.city is Some(city) {
    obj["city"] = city.to_json()
  }
  if self.country is Some(country) {
    obj["country"] = country.to_json()
  }
  if self.region is Some(region) {
    obj["region"] = region.to_json()
  }
  if self.timezone is Some(timezone) {
    obj["timezone"] = timezone.to_json()
  }
  if self.type_ is Some(type_) {
    obj["type"] = type_.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for WebSearchToolUserLocation with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchToolUserLocation raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let city : String? = object.optional("city", path~)
  let country : String? = object.optional("country", path~)
  let region : String? = object.optional("region", path~)
  let timezone : String? = object.optional("timezone", path~)
  let type_ : String? = object.optional("type", path~)
  WebSearchToolUserLocation::{ city, country, region, timezone, type_ }
}

///|
pub impl ToJson for WebSearchTool with to_json(self : WebSearchTool) -> Json {
  let obj : Map[String, Json] = { "type": self.type_ }
  if self.filters is Some(filters) {
    obj["filters"] = filters.to_json()
  }
  if self.search_context_size is Some(search_context_size) {
    obj["search_context_size"] = search_context_size.to_json()
  }
  if self.user_location is Some(user_location) {
    obj["user_location"] = user_location.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for WebSearchTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : WebSearchToolType = object.required("type", path~)
  let filters : WebSearchToolFilters? = object.optional("filters", path~)
  let search_context_size : WebSearchToolSearchContextSize? = object.optional(
    "search_context_size",
    path~,
  )
  let user_location : WebSearchToolUserLocation? = object.optional(
    "user_location",
    path~,
  )
  WebSearchTool::{ type_, filters, search_context_size, user_location }
}

///|
/// Web search preview tool definition.
pub struct WebSearchPreviewTool {
  type_ : WebSearchPreviewToolType
  search_context_size : WebSearchPreviewToolSearchContextSize?
  user_location : WebSearchPreviewToolUserLocation?
}

///|
pub enum WebSearchPreviewToolType {
  WebSearchPreview
  WebSearchPreview2025_03_11
}

///|
pub impl ToJson for WebSearchPreviewToolType with to_json(
  self : WebSearchPreviewToolType,
) -> Json {
  match self {
    WebSearchPreview => "web_search_preview"
    WebSearchPreview2025_03_11 => "web_search_preview_2025_03_11"
  }
}

///|
pub impl @json.FromJson for WebSearchPreviewToolType with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchPreviewToolType raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "WebSearchPreviewToolType: expected string"),
    )
  }
  match value {
    "web_search_preview" => WebSearchPreview
    "web_search_preview_2025_03_11" => WebSearchPreview2025_03_11
    _ =>
      raise @json.JsonDecodeError(
        (path, "WebSearchPreviewToolType: invalid value '\{value}'"),
      )
  }
}

///|
pub enum WebSearchPreviewToolSearchContextSize {
  Low
  Medium
  High
}

///|
pub impl ToJson for WebSearchPreviewToolSearchContextSize with to_json(
  self : WebSearchPreviewToolSearchContextSize,
) -> Json {
  match self {
    Low => "low"
    Medium => "medium"
    High => "high"
  }
}

///|
pub impl @json.FromJson for WebSearchPreviewToolSearchContextSize with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchPreviewToolSearchContextSize raise @json.JsonDecodeError {
  guard json is String(value) else {
    raise @json.JsonDecodeError(
      (path, "WebSearchPreviewToolSearchContextSize: expected string"),
    )
  }
  match value {
    "low" => Low
    "medium" => Medium
    "high" => High
    _ =>
      raise @json.JsonDecodeError(
        (
          path,
          "WebSearchPreviewToolSearchContextSize: invalid value '\{value}'",
        ),
      )
  }
}

///|
pub struct WebSearchPreviewToolUserLocation {
  city : String?
  country : String?
  region : String?
  timezone : String?
}

///|
pub impl ToJson for WebSearchPreviewToolUserLocation with to_json(
  self : WebSearchPreviewToolUserLocation,
) -> Json {
  let obj : Map[String, Json] = { "type": "approximate" }
  if self.city is Some(city) {
    obj["city"] = city.to_json()
  }
  if self.country is Some(country) {
    obj["country"] = country.to_json()
  }
  if self.region is Some(region) {
    obj["region"] = region.to_json()
  }
  if self.timezone is Some(timezone) {
    obj["timezone"] = timezone.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for WebSearchPreviewToolUserLocation with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchPreviewToolUserLocation raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let city : String? = object.optional("city", path~)
  let country : String? = object.optional("country", path~)
  let region : String? = object.optional("region", path~)
  let timezone : String? = object.optional("timezone", path~)
  WebSearchPreviewToolUserLocation::{ city, country, region, timezone }
}

///|
pub impl ToJson for WebSearchPreviewTool with to_json(
  self : WebSearchPreviewTool,
) -> Json {
  let obj : Map[String, Json] = { "type": self.type_ }
  if self.search_context_size is Some(search_context_size) {
    obj["search_context_size"] = search_context_size.to_json()
  }
  if self.user_location is Some(user_location) {
    obj["user_location"] = user_location.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for WebSearchPreviewTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> WebSearchPreviewTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : WebSearchPreviewToolType = object.required("type", path~)
  let search_context_size : WebSearchPreviewToolSearchContextSize? = object.optional(
    "search_context_size",
    path~,
  )
  let user_location : WebSearchPreviewToolUserLocation? = object.optional(
    "user_location",
    path~,
  )
  WebSearchPreviewTool::{ type_, search_context_size, user_location }
}

///|
/// MCP tool definition.
pub struct ToolMcp {
  server_label : String
  allowed_tools : ToolMcpAllowedTools?
  authorization : String?
  connector_id : String?
  headers : Map[String, String]?
  require_approval : ToolMcpRequireApproval?
  server_description : String?
  server_url : String?
}

///|
pub enum ToolMcpAllowedTools {
  ToolNames(Array[String])
  Filter(ToolMcpAllowedToolsMcpToolFilter)
}

///|
pub struct ToolMcpAllowedToolsMcpToolFilter {
  read_only : Bool?
  tool_names : Array[String]?
}

///|
pub impl ToJson for ToolMcpAllowedToolsMcpToolFilter with to_json(
  self : ToolMcpAllowedToolsMcpToolFilter,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.read_only is Some(read_only) {
    obj["read_only"] = read_only.to_json()
  }
  if self.tool_names is Some(tool_names) {
    obj["tool_names"] = tool_names.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolMcpAllowedToolsMcpToolFilter with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcpAllowedToolsMcpToolFilter raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let read_only : Bool? = object.optional("read_only", path~)
  let tool_names : Array[String]? = object.optional("tool_names", path~)
  ToolMcpAllowedToolsMcpToolFilter::{ read_only, tool_names }
}

///|
pub impl ToJson for ToolMcpAllowedTools with to_json(self : ToolMcpAllowedTools) -> Json {
  match self {
    ToolNames(names) => names.to_json()
    Filter(filter) => filter.to_json()
  }
}

///|
pub impl @json.FromJson for ToolMcpAllowedTools with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcpAllowedTools raise @json.JsonDecodeError {
  match json {
    Array(_) => ToolNames(@json.from_json(json, path~))
    Object(_) => Filter(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError((path, "ToolMcpAllowedTools: invalid value"))
  }
}

///|
pub enum ToolMcpRequireApproval {
  Setting(String)
  Filter(ToolMcpRequireApprovalMcpToolApprovalFilter)
}

///|
pub struct ToolMcpRequireApprovalMcpToolApprovalFilter {
  always : ToolMcpRequireApprovalMcpToolApprovalFilterAlways?
  never : ToolMcpRequireApprovalMcpToolApprovalFilterNever?
}

///|
pub struct ToolMcpRequireApprovalMcpToolApprovalFilterAlways {
  read_only : Bool?
  tool_names : Array[String]?
}

///|
pub struct ToolMcpRequireApprovalMcpToolApprovalFilterNever {
  read_only : Bool?
  tool_names : Array[String]?
}

///|
pub impl ToJson for ToolMcpRequireApprovalMcpToolApprovalFilterAlways with to_json(
  self : ToolMcpRequireApprovalMcpToolApprovalFilterAlways,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.read_only is Some(read_only) {
    obj["read_only"] = read_only.to_json()
  }
  if self.tool_names is Some(tool_names) {
    obj["tool_names"] = tool_names.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolMcpRequireApprovalMcpToolApprovalFilterAlways with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcpRequireApprovalMcpToolApprovalFilterAlways raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let read_only : Bool? = object.optional("read_only", path~)
  let tool_names : Array[String]? = object.optional("tool_names", path~)
  ToolMcpRequireApprovalMcpToolApprovalFilterAlways::{ read_only, tool_names }
}

///|
pub impl ToJson for ToolMcpRequireApprovalMcpToolApprovalFilterNever with to_json(
  self : ToolMcpRequireApprovalMcpToolApprovalFilterNever,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.read_only is Some(read_only) {
    obj["read_only"] = read_only.to_json()
  }
  if self.tool_names is Some(tool_names) {
    obj["tool_names"] = tool_names.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolMcpRequireApprovalMcpToolApprovalFilterNever with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcpRequireApprovalMcpToolApprovalFilterNever raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let read_only : Bool? = object.optional("read_only", path~)
  let tool_names : Array[String]? = object.optional("tool_names", path~)
  ToolMcpRequireApprovalMcpToolApprovalFilterNever::{ read_only, tool_names }
}

///|
pub impl ToJson for ToolMcpRequireApprovalMcpToolApprovalFilter with to_json(
  self : ToolMcpRequireApprovalMcpToolApprovalFilter,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.always is Some(always) {
    obj["always"] = always.to_json()
  }
  if self.never is Some(never) {
    obj["never"] = never.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolMcpRequireApprovalMcpToolApprovalFilter with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcpRequireApprovalMcpToolApprovalFilter raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let always : ToolMcpRequireApprovalMcpToolApprovalFilterAlways? = object.optional(
    "always",
    path~,
  )
  let never : ToolMcpRequireApprovalMcpToolApprovalFilterNever? = object.optional(
    "never",
    path~,
  )
  ToolMcpRequireApprovalMcpToolApprovalFilter::{ always, never }
}

///|
pub impl ToJson for ToolMcpRequireApproval with to_json(
  self : ToolMcpRequireApproval,
) -> Json {
  match self {
    Setting(value) => value.to_json()
    Filter(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ToolMcpRequireApproval with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcpRequireApproval raise @json.JsonDecodeError {
  match json {
    String(value) => Setting(value)
    Object(_) => Filter(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "ToolMcpRequireApproval: invalid value"),
      )
  }
}

///|
pub impl ToJson for ToolMcp with to_json(self : ToolMcp) -> Json {
  let obj : Map[String, Json] = {
    "server_label": self.server_label,
    "type": "mcp",
  }
  if self.allowed_tools is Some(allowed_tools) {
    obj["allowed_tools"] = allowed_tools.to_json()
  }
  if self.authorization is Some(authorization) {
    obj["authorization"] = authorization.to_json()
  }
  if self.connector_id is Some(connector_id) {
    obj["connector_id"] = connector_id.to_json()
  }
  if self.headers is Some(headers) {
    obj["headers"] = headers.to_json()
  }
  if self.require_approval is Some(require_approval) {
    obj["require_approval"] = require_approval.to_json()
  }
  if self.server_description is Some(server_description) {
    obj["server_description"] = server_description.to_json()
  }
  if self.server_url is Some(server_url) {
    obj["server_url"] = server_url.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolMcp with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolMcp raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let server_label : String = object.required("server_label", path~)
  let _ : String = object.required("type", path~)
  let allowed_tools : ToolMcpAllowedTools? = object.optional(
    "allowed_tools",
    path~,
  )
  let authorization : String? = object.optional("authorization", path~)
  let connector_id : String? = object.optional("connector_id", path~)
  let headers : Map[String, String]? = object.optional("headers", path~)
  let require_approval : ToolMcpRequireApproval? = object.optional(
    "require_approval",
    path~,
  )
  let server_description : String? = object.optional(
    "server_description",
    path~,
  )
  let server_url : String? = object.optional("server_url", path~)
  ToolMcp::{
    server_label,
    allowed_tools,
    authorization,
    connector_id,
    headers,
    require_approval,
    server_description,
    server_url,
  }
}

///|
/// Code interpreter tool definition.
pub struct ToolCodeInterpreter {
  container : ToolCodeInterpreterContainer
}

///|
pub enum ToolCodeInterpreterContainer {
  ContainerId(String)
  Auto(ToolCodeInterpreterContainerAuto)
}

///|
pub struct ToolCodeInterpreterContainerAuto {
  file_ids : Array[String]?
  memory_limit : String?
}

///|
pub impl ToJson for ToolCodeInterpreterContainerAuto with to_json(
  self : ToolCodeInterpreterContainerAuto,
) -> Json {
  let obj : Map[String, Json] = { "type": "auto" }
  if self.file_ids is Some(file_ids) {
    obj["file_ids"] = file_ids.to_json()
  }
  if self.memory_limit is Some(memory_limit) {
    obj["memory_limit"] = memory_limit.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolCodeInterpreterContainerAuto with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolCodeInterpreterContainerAuto raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let file_ids : Array[String]? = object.optional("file_ids", path~)
  let memory_limit : String? = object.optional("memory_limit", path~)
  ToolCodeInterpreterContainerAuto::{ file_ids, memory_limit }
}

///|
pub impl ToJson for ToolCodeInterpreterContainer with to_json(
  self : ToolCodeInterpreterContainer,
) -> Json {
  match self {
    ContainerId(value) => value.to_json()
    Auto(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ToolCodeInterpreterContainer with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolCodeInterpreterContainer raise @json.JsonDecodeError {
  match json {
    String(value) => ContainerId(value)
    Object(_) => Auto(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path, "ToolCodeInterpreterContainer: invalid value"),
      )
  }
}

///|
pub impl ToJson for ToolCodeInterpreter with to_json(self : ToolCodeInterpreter) -> Json {
  { "container": self.container, "type": "code_interpreter" }
}

///|
pub impl @json.FromJson for ToolCodeInterpreter with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolCodeInterpreter raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let container : ToolCodeInterpreterContainer = object.required(
    "container",
    path~,
  )
  let _ : String = object.required("type", path~)
  ToolCodeInterpreter::{ container, }
}

///|
/// Image generation tool definition.
pub struct ToolImageGeneration {
  background : String?
  input_fidelity : String?
  input_image_mask : ToolImageGenerationInputImageMask?
  model : String?
  moderation : String?
  output_compression : Int64?
  output_format : String?
  partial_images : Int64?
  quality : String?
  size : String?
}

///|
pub struct ToolImageGenerationInputImageMask {
  file_id : String?
  image_url : String?
}

///|
pub impl ToJson for ToolImageGenerationInputImageMask with to_json(
  self : ToolImageGenerationInputImageMask,
) -> Json {
  let obj : Map[String, Json] = {}
  if self.file_id is Some(file_id) {
    obj["file_id"] = file_id.to_json()
  }
  if self.image_url is Some(image_url) {
    obj["image_url"] = image_url.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolImageGenerationInputImageMask with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolImageGenerationInputImageMask raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let file_id : String? = object.optional("file_id", path~)
  let image_url : String? = object.optional("image_url", path~)
  ToolImageGenerationInputImageMask::{ file_id, image_url }
}

///|
pub impl ToJson for ToolImageGeneration with to_json(self : ToolImageGeneration) -> Json {
  let obj : Map[String, Json] = { "type": "image_generation" }
  if self.background is Some(background) {
    obj["background"] = background.to_json()
  }
  if self.input_fidelity is Some(input_fidelity) {
    obj["input_fidelity"] = input_fidelity.to_json()
  }
  if self.input_image_mask is Some(input_image_mask) {
    obj["input_image_mask"] = input_image_mask.to_json()
  }
  if self.model is Some(model) {
    obj["model"] = model.to_json()
  }
  if self.moderation is Some(moderation) {
    obj["moderation"] = moderation.to_json()
  }
  if self.output_compression is Some(output_compression) {
    obj["output_compression"] = output_compression.to_json()
  }
  if self.output_format is Some(output_format) {
    obj["output_format"] = output_format.to_json()
  }
  if self.partial_images is Some(partial_images) {
    obj["partial_images"] = partial_images.to_json()
  }
  if self.quality is Some(quality) {
    obj["quality"] = quality.to_json()
  }
  if self.size is Some(size) {
    obj["size"] = size.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ToolImageGeneration with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolImageGeneration raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let background : String? = object.optional("background", path~)
  let input_fidelity : String? = object.optional("input_fidelity", path~)
  let input_image_mask : ToolImageGenerationInputImageMask? = object.optional(
    "input_image_mask",
    path~,
  )
  let model : String? = object.optional("model", path~)
  let moderation : String? = object.optional("moderation", path~)
  let output_compression : Int64? = object.optional("output_compression", path~)
  let output_format : String? = object.optional("output_format", path~)
  let partial_images : Int64? = object.optional("partial_images", path~)
  let quality : String? = object.optional("quality", path~)
  let size : String? = object.optional("size", path~)
  ToolImageGeneration::{
    background,
    input_fidelity,
    input_image_mask,
    model,
    moderation,
    output_compression,
    output_format,
    partial_images,
    quality,
    size,
  }
}

///|
/// Local shell tool definition.
pub struct ToolLocalShell {}

///|
pub impl ToJson for ToolLocalShell with to_json(_ : ToolLocalShell) -> Json {
  { "type": "local_shell" }
}

///|
pub impl @json.FromJson for ToolLocalShell with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ToolLocalShell raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ToolLocalShell::{  }
}

///|
/// Shell tool definition.
pub struct FunctionShellTool {}

///|
pub impl ToJson for FunctionShellTool with to_json(_ : FunctionShellTool) -> Json {
  { "type": "shell" }
}

///|
pub impl @json.FromJson for FunctionShellTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> FunctionShellTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  FunctionShellTool::{  }
}

///|
/// Custom tool definition.
pub struct CustomTool {
  name : String
  description : String?
  format : @shared.CustomToolInputFormatUnion?
}

///|
pub impl ToJson for CustomTool with to_json(self : CustomTool) -> Json {
  let obj : Map[String, Json] = { "name": self.name, "type": "custom" }
  if self.description is Some(description) {
    obj["description"] = description.to_json()
  }
  if self.format is Some(format) {
    obj["format"] = format.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for CustomTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CustomTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let name : String = object.required("name", path~)
  let _ : String = object.required("type", path~)
  let description : String? = object.optional("description", path~)
  let format : @shared.CustomToolInputFormatUnion? = object.optional(
    "format",
    path~,
  )
  CustomTool::{ name, description, format }
}

///|
/// Apply patch tool definition.
pub struct ApplyPatchTool {}

///|
pub impl ToJson for ApplyPatchTool with to_json(_ : ApplyPatchTool) -> Json {
  { "type": "apply_patch" }
}

///|
pub impl @json.FromJson for ApplyPatchTool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ApplyPatchTool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ApplyPatchTool::{  }
}

///|
/// Tool union used by responses.
pub enum Tool {
  Function(FunctionTool)
  FileSearch(FileSearchTool)
  ComputerUsePreview(ComputerTool)
  WebSearch(WebSearchTool)
  Mcp(ToolMcp)
  CodeInterpreter(ToolCodeInterpreter)
  ImageGeneration(ToolImageGeneration)
  LocalShell(ToolLocalShell)
  Shell(FunctionShellTool)
  Custom(CustomTool)
  WebSearchPreview(WebSearchPreviewTool)
  ApplyPatch(ApplyPatchTool)
}

///|
pub impl ToJson for Tool with to_json(self : Tool) -> Json {
  match self {
    Function(value) => value.to_json()
    FileSearch(value) => value.to_json()
    ComputerUsePreview(value) => value.to_json()
    WebSearch(value) => value.to_json()
    Mcp(value) => value.to_json()
    CodeInterpreter(value) => value.to_json()
    ImageGeneration(value) => value.to_json()
    LocalShell(value) => value.to_json()
    Shell(value) => value.to_json()
    Custom(value) => value.to_json()
    WebSearchPreview(value) => value.to_json()
    ApplyPatch(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for Tool with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Tool raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "function" => Function(@json.from_json(json, path~))
    "file_search" => FileSearch(@json.from_json(json, path~))
    "computer_use_preview" => ComputerUsePreview(@json.from_json(json, path~))
    "web_search" | "web_search_2025_08_26" =>
      WebSearch(@json.from_json(json, path~))
    "mcp" => Mcp(@json.from_json(json, path~))
    "code_interpreter" => CodeInterpreter(@json.from_json(json, path~))
    "image_generation" => ImageGeneration(@json.from_json(json, path~))
    "local_shell" => LocalShell(@json.from_json(json, path~))
    "shell" => Shell(@json.from_json(json, path~))
    "custom" => Custom(@json.from_json(json, path~))
    "web_search_preview" | "web_search_preview_2025_03_11" =>
      WebSearchPreview(@json.from_json(json, path~))
    "apply_patch" => ApplyPatch(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (path.add_key("type"), "Tool: invalid type '\{type_}'"),
      )
  }
}
