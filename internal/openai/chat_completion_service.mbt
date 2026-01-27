///|
pub suberror ChatCompletionServiceError {
  ChatInvalidRequestBody
  ChatMissingCompletionId
  ChatHttpError(code~ : Int, body~ : String)
} derive(Show, ToJson)

///|
pub type ChatCompletionNewParams = Request

///|
pub struct ChatCompletionStream {
  client : @http.Client
}

///|
pub async fn ChatCompletionStream::read(
  self : ChatCompletionStream,
) -> ChatCompletionChunk? {
  guard @client.read_sse_line(self.client) is Some(data) else { return None }
  try {
    let json = @json.parse(data)
    let chunk : ChatCompletionChunk = @json.from_json(json)
    Some(chunk)
  } catch {
    _ => None
  }
}

///|
pub fn ChatCompletionStream::close(self : ChatCompletionStream) -> Unit {
  self.client.close()
}

///|
pub struct ChatCompletionService {
  base_url : String
  api_key : String
}

///|
pub fn ChatCompletionService::new(
  base_url~ : String,
  api_key~ : String,
) -> ChatCompletionService {
  { base_url, api_key }
}

///|
pub async fn ChatCompletionService::create(
  self : ChatCompletionService,
  body : ChatCompletionNewParams,
) -> ChatCompletion {
  let url = "\{self.base_url}/chat/completions"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let json_body = body.to_json()
  guard json_body is Object(obj) else { raise ChatInvalidRequestBody }
  let response = client.post(path, Json::object(obj))
  guard response.code >= 200 && response.code <= 299 else {
    raise ChatHttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ChatCompletionService::create_stream(
  self : ChatCompletionService,
  body : ChatCompletionNewParams,
) -> ChatCompletionStream {
  let url = "\{self.base_url}/chat/completions"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=true,
  )
  let json_body = body.to_json()
  guard json_body is Object(obj) else {
    client.close()
    raise ChatInvalidRequestBody
  }
  obj["stream"] = true.to_json()
  let response = client.post(path, Json::object(obj))
  guard response.code >= 200 && response.code <= 299 else {
    let error_body = client.read_all().text()
    client.close()
    raise ChatHttpError(code=response.code, body=error_body)
  }
  ChatCompletionStream::{ client, }
}

///|
pub async fn ChatCompletionService::get(
  self : ChatCompletionService,
  completion_id : String,
) -> ChatCompletion {
  guard !completion_id.is_empty() else { raise ChatMissingCompletionId }
  let url = "\{self.base_url}/chat/completions/\{completion_id}"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let response = client.get(path)
  guard response.code >= 200 && response.code <= 299 else {
    raise ChatHttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ChatCompletionService::update(
  self : ChatCompletionService,
  completion_id : String,
  body : ChatCompletionUpdateParams,
) -> ChatCompletion {
  guard !completion_id.is_empty() else { raise ChatMissingCompletionId }
  let url = "\{self.base_url}/chat/completions/\{completion_id}"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let json_body = body.to_json()
  guard json_body is Object(obj) else { raise ChatInvalidRequestBody }
  let response = client.post(path, Json::object(obj))
  guard response.code >= 200 && response.code <= 299 else {
    raise ChatHttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ChatCompletionService::list(
  self : ChatCompletionService,
  query? : ChatCompletionListParams = ChatCompletionListParams::empty(),
) -> ChatCompletionListResponse {
  let query_str = query.to_query_string()
  let url = "\{self.base_url}/chat/completions\{query_str}"
  let (client, path) = @client.build_http_client(
    url,
    self.api_key,
    accept_stream=false,
  )
  defer client.close()
  let response = client.get(path)
  guard response.code >= 200 && response.code <= 299 else {
    raise ChatHttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}

///|
pub async fn ChatCompletionService::delete(
  self : ChatCompletionService,
  completion_id : String,
) -> ChatCompletionDeleted {
  guard !completion_id.is_empty() else { raise ChatMissingCompletionId }
  let url = "\{self.base_url}/chat/completions/\{completion_id}"
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
    raise ChatHttpError(code=response.code, body=client.read_all().text())
  }
  @client.parse_json_response(client.read_all().text())
}
