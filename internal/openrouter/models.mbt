///|
pub struct Pricing {
  prompt : String
  completion : String
  request : String?
  image : String?
  web_search : String?
  internal_reasoning : String?
  input_cache_read : String?
  input_cache_write : String?
} derive(ToJson)

///|
pub impl @json.FromJson for Pricing with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Pricing raise @json.JsonDecodeError {
  guard json is @json.Object(json) else {
    raise @json.JsonDecodeError(
      (path, "\{PackageName}.Pricing::from_json: expected object"),
    )
  }
  let prompt : String = {
    guard json.get("prompt") is Some(prompt_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("prompt"),
          "\{PackageName}.Pricing::from_json: missing field prompt",
        ),
      )
    }
    @json.from_json(prompt_json, path=path.add_key("prompt"))
  }
  let completion : String = {
    guard json.get("completion") is Some(completion_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("completion"),
          "\{PackageName}.Pricing::from_json: missing field completion",
        ),
      )
    }
    @json.from_json(completion_json, path=path.add_key("completion"))
  }
  let request : String? = match json.get("request") {
    Some(Null) => None
    Some(request_json) =>
      Some(@json.from_json(request_json, path=path.add_key("request")))
    None => None
  }
  let image : String? = match json.get("image") {
    Some(Null) => None
    Some(image_json) =>
      Some(@json.from_json(image_json, path=path.add_key("image")))
    None => None
  }
  let web_search : String? = match json.get("web_search") {
    Some(Null) => None
    Some(web_search_json) =>
      Some(@json.from_json(web_search_json, path=path.add_key("web_search")))
    None => None
  }
  let internal_reasoning : String? = match json.get("internal_reasoning") {
    Some(Null) => None
    Some(internal_reasoning_json) =>
      Some(
        @json.from_json(
          internal_reasoning_json,
          path=path.add_key("internal_reasoning"),
        ),
      )
    None => None
  }
  let input_cache_read : String? = match json.get("input_cache_read") {
    Some(Null) => None
    Some(input_cache_read_json) =>
      Some(
        @json.from_json(
          input_cache_read_json,
          path=path.add_key("input_cache_read"),
        ),
      )
    None => None
  }
  let input_cache_write : String? = match json.get("input_cache_write") {
    Some(Null) => None
    Some(input_cache_write_json) =>
      Some(
        @json.from_json(
          input_cache_write_json,
          path=path.add_key("input_cache_write"),
        ),
      )
    None => None
  }
  Pricing::{
    prompt,
    completion,
    request,
    image,
    web_search,
    internal_reasoning,
    input_cache_read,
    input_cache_write,
  }
}

///|
pub suberror InvalidResponse {
  InvalidResponse(@http.Response, &@io.Data)
}

///|
pub async fn get_models(api_key~ : StringView) -> Array[Model] {
  let (r, b) = @http.get("https://openrouter.ai/api/v1/models", headers={
    "Authorization": "Bearer \{api_key}",
  })
  guard b.json() is { "data": data_json, .. } else {
    raise InvalidResponse(r, b)
  }
  @json.from_json(data_json)
}

///|
pub async fn get_models_count(api_key~ : StringView) -> Int {
  let (r, b) = @http.get("https://openrouter.ai/api/v1/models/count", headers={
    "Authorization": "Bearer \{api_key}",
  })
  guard b.json() is { "data": { "count": count_json, .. }, .. } else {
    raise InvalidResponse(r, b)
  }
  @json.from_json(count_json)
}
