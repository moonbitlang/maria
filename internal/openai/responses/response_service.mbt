///|
pub suberror ResponseServiceError {
  InvalidRequestBody
  MissingResponseId
  HttpError(code~ : Int, body~ : String)
} derive(Show, ToJson)

///|
pub type ResponseNewParams = ResponsesRequest

///|
pub struct ResponseGetParams {
  include_obfuscation : Bool?
  starting_after : Int64?
  include_items : Array[String]
}

///|
pub fn ResponseGetParams::empty() -> ResponseGetParams {
  { include_obfuscation: None, starting_after: None, include_items: [] }
}

///|
fn ResponseGetParams::to_query_string(self : ResponseGetParams) -> String {
  let parts : Array[String] = []
  if self.include_obfuscation is Some(value) {
    let bool_value = if value { "true" } else { "false" }
    parts.push(
      "include_obfuscation=\{@client.encode_query_component(bool_value)}",
    )
  }
  if self.starting_after is Some(value) {
    parts.push(
      "starting_after=\{@client.encode_query_component(value.to_string())}",
    )
  }
  for item in self.include_items {
    parts.push("include[]=\{@client.encode_query_component(item)}")
  }
  if parts.is_empty() {
    ""
  } else {
    let joined = parts.join("&")
    "?\{joined}"
  }
}

///|
pub struct ResponseCompactParams {
  model : @shared.ResponsesModel
  input : Array[ResponseInputItemParam]?
  instructions : String?
  previous_response_id : String?
}

///|
pub fn ResponseCompactParams::new(
  model~ : @shared.ResponsesModel,
  input? : Array[ResponseInputItemParam],
  instructions? : String,
  previous_response_id? : String,
) -> ResponseCompactParams {
  { model, input, instructions, previous_response_id }
}

///|
pub impl ToJson for ResponseCompactParams with to_json(
  self : ResponseCompactParams,
) -> Json {
  let obj : Map[String, Json] = { "model": self.model.to_json() }
  if self.input is Some(input) {
    obj["input"] = input.to_json()
  }
  if self.instructions is Some(instructions) {
    obj["instructions"] = instructions.to_json()
  }
  if self.previous_response_id is Some(previous_response_id) {
    obj["previous_response_id"] = previous_response_id.to_json()
  }
  Json::object(obj)
}

///|
pub struct CompactedResponse {
  id : String
  created_at : Int64
  object_ : String
  output : Array[ResponseOutputItem]
  usage : ResponseUsage
}

///|
pub impl @json.FromJson for CompactedResponse with from_json(
  json : Json,
  path : @json.JsonPath,
) -> CompactedResponse raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let id : String = object.required("id", path~)
  let created_at : Int64 = @jsonx.as_int64(
    object.required("created_at", path~),
    path=path.add_key("created_at"),
  )
  let object_ : String = object.required("object", path~)
  let output : Array[ResponseOutputItem] = object.required("output", path~)
  let usage : ResponseUsage = object.required("usage", path~)
  CompactedResponse::{ id, created_at, object_, output, usage }
}

///|
pub struct ResponseStream {
  client : @http.Client
}

///|
pub async fn ResponseStream::read(
  self : ResponseStream,
) -> ResponseStreamEvent? {
  guard @client.read_sse_line(self.client) is Some(data) else { return None }
  try {
    let json = @json.parse(data)
    let event : ResponseStreamEvent = @json.from_json(json)
    Some(event)
  } catch {
    _ => None
  }
}

///|
pub fn ResponseStream::close(self : ResponseStream) -> Unit {
  self.client.close()
}

///|
pub struct ResponseService {
  base_url : String
  api_key : String
}

///|
pub fn ResponseService::new(
  base_url~ : String,
  api_key~ : String,
) -> ResponseService {
  { base_url, api_key }
}

///|
pub async fn ResponseService::create(
  self : ResponseService,
  body : ResponseNewParams,
) -> Response {
  let url = "\{self.base_url}/responses"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let json_body = body.to_json()
  guard json_body is Object(obj) else { raise InvalidRequestBody }
  let response = client.post(path, Json::object(obj))
  guard response.code >= 200 && response.code <= 299 else {
    raise HttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ResponseService::create_stream(
  self : ResponseService,
  body : ResponseNewParams,
) -> ResponseStream {
  let url = "\{self.base_url}/responses"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=true,
  )
  let json_body = body.to_json()
  guard json_body is Object(obj) else {
    client.close()
    raise InvalidRequestBody
  }
  obj["stream"] = true.to_json()
  let response = client.post(path, Json::object(obj))
  guard response.code >= 200 && response.code <= 299 else {
    let error_body = client.read_all().text()
    client.close()
    raise HttpError(code=response.code, body=error_body)
  }
  ResponseStream::{ client, }
}

///|
pub async fn ResponseService::get(
  self : ResponseService,
  response_id : String,
  query? : ResponseGetParams = ResponseGetParams::empty(),
) -> Response {
  guard !response_id.is_empty() else { raise MissingResponseId }
  let query_str = query.to_query_string()
  let url = "\{self.base_url}/responses/\{response_id}\{query_str}"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let response = client.get(path)
  guard response.code >= 200 && response.code <= 299 else {
    raise HttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ResponseService::get_stream(
  self : ResponseService,
  response_id : String,
  query? : ResponseGetParams = ResponseGetParams::empty(),
) -> ResponseStream {
  guard !response_id.is_empty() else { raise MissingResponseId }
  let query_str = @client.add_query_param(
    query.to_query_string(),
    "stream",
    "true",
  )
  let url = "\{self.base_url}/responses/\{response_id}\{query_str}"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=true,
  )
  let response = client.get(path)
  guard response.code >= 200 && response.code <= 299 else {
    let error_body = client.read_all().text()
    client.close()
    raise HttpError(code=response.code, body=error_body)
  }
  ResponseStream::{ client, }
}

///|
pub async fn ResponseService::delete(
  self : ResponseService,
  response_id : String,
) -> Unit {
  guard !response_id.is_empty() else { raise MissingResponseId }
  let url = "\{self.base_url}/responses/\{response_id}"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  client.request(@http.RequestMethod::Delete, path, extra_headers={
    "Accept": "*/*",
  })
  let response = client.end_request()
  guard response.code >= 200 && response.code <= 299 else {
    raise HttpError(code=response.code, body=client.read_all().text())
  }
  ignore(client.read_all())
}

///|
pub async fn ResponseService::cancel(
  self : ResponseService,
  response_id : String,
) -> Response {
  guard !response_id.is_empty() else { raise MissingResponseId }
  let url = "\{self.base_url}/responses/\{response_id}/cancel"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  client.request(@http.RequestMethod::Post, path)
  let response = client.end_request()
  guard response.code >= 200 && response.code <= 299 else {
    raise HttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ResponseService::compact(
  self : ResponseService,
  body : ResponseCompactParams,
) -> CompactedResponse {
  let url = "\{self.base_url}/responses/compact"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let json_body = body.to_json()
  guard json_body is Object(obj) else { raise InvalidRequestBody }
  let response = client.post(path, Json::object(obj))
  guard response.code >= 200 && response.code <= 299 else {
    raise HttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}
