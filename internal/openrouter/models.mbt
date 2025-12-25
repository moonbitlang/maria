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
