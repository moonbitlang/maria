///|
pub struct Model {
  id : String
  canonical_slug : String
  name : String
  created : Int64
  description : String
  context_length : Int
  architecture : Architecture
  pricing : Pricing
  top_provider : TopProvider
  per_request_limits : Json?
  supported_parameters : Array[String]
} derive(ToJson)

///|
const PackageName = "@moonbitlang/maria/internal/openrouter"

///|
pub impl @json.FromJson for Model with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Model raise @json.JsonDecodeError {
  guard json is @json.Object(json) else {
    raise @json.JsonDecodeError(
      (path, "\{PackageName}.Model::from_json: expected object"),
    )
  }
  let id : String = {
    guard json.get("id") is Some(id_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("id"),
          "\{PackageName}.Model::from_json: missing field id",
        ),
      )
    }
    @json.from_json(id_json, path=path.add_key("id"))
  }
  let canonical_slug : String = {
    guard json.get("canonical_slug") is Some(canonical_slug_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("canonical_slug"),
          "\{PackageName}.Model::from_json: missing field canonical_slug",
        ),
      )
    }
    @json.from_json(canonical_slug_json, path=path.add_key("canonical_slug"))
  }
  let name : String = {
    guard json.get("name") is Some(name_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("name"),
          "\{PackageName}.Model::from_json: missing field name",
        ),
      )
    }
    @json.from_json(name_json, path=path.add_key("name"))
  }
  let created : Int64 = {
    guard json.get("created") is Some(created_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("created"),
          "\{PackageName}.Model::from_json: missing field created",
        ),
      )
    }
    match created_json {
      Number(_, repr=Some(created_repr)) =>
        @strconv.parse_int64(created_repr) catch {
          error =>
            raise @json.JsonDecodeError(
              (
                path.add_key("created"),
                "\{PackageName}.Model::from_json: invalid number for created: \{error}",
              ),
            )
        }
      Number(created_number, repr=None) =>
        @strconv.parse_int64(created_number.to_string()) catch {
          error =>
            raise @json.JsonDecodeError(
              (
                path.add_key("created"),
                "\{PackageName}.Model::from_json: invalid number for created: \{error}",
              ),
            )
        }
      _ =>
        raise @json.JsonDecodeError(
          (
            path.add_key("created"),
            "\{PackageName}.Model::from_json: expected number for created",
          ),
        )
    }
  }
  let description : String = {
    guard json.get("description") is Some(description_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("description"),
          "\{PackageName}.Model::from_json: missing field description",
        ),
      )
    }
    @json.from_json(description_json, path=path.add_key("description"))
  }
  let context_length : Int = {
    guard json.get("context_length") is Some(context_length_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("context_length"),
          "\{PackageName}.Model::from_json: missing field context_length",
        ),
      )
    }
    @json.from_json(context_length_json, path=path.add_key("context_length"))
  }
  let architecture : Architecture = {
    guard json.get("architecture") is Some(architecture_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("architecture"),
          "\{PackageName}.Model::from_json: missing field architecture",
        ),
      )
    }
    @json.from_json(architecture_json, path=path.add_key("architecture"))
  }
  let pricing : Pricing = {
    guard json.get("pricing") is Some(pricing_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("pricing"),
          "\{PackageName}.Model::from_json: missing field pricing",
        ),
      )
    }
    @json.from_json(pricing_json, path=path.add_key("pricing"))
  }
  let top_provider : TopProvider = {
    guard json.get("top_provider") is Some(top_provider_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("top_provider"),
          "\{PackageName}.Model::from_json: missing field top_provider",
        ),
      )
    }
    @json.from_json(top_provider_json, path=path.add_key("top_provider"))
  }
  let per_request_limits : Json? = json.get("per_request_limits")
  let supported_parameters : Array[String] = {
    guard json.get("supported_parameters") is Some(supported_parameters_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("supported_parameters"),
          "\{PackageName}.Model::from_json: missing field supported_parameters",
        ),
      )
    }
    @json.from_json(
      supported_parameters_json,
      path=path.add_key("supported_parameters"),
    )
  }
  Model::{
    id,
    canonical_slug,
    name,
    created,
    description,
    context_length,
    architecture,
    pricing,
    top_provider,
    per_request_limits,
    supported_parameters,
  }
}

///|
pub struct Architecture {
  input_modalities : Array[String]
  output_modalities : Array[String]
  tokenizer : String
  instruct_type : String?
} derive(ToJson)

///|
pub impl @json.FromJson for Architecture with from_json(
  json : Json,
  path : @json.JsonPath,
) -> Architecture raise @json.JsonDecodeError {
  guard json is @json.Object(json) else {
    raise @json.JsonDecodeError(
      (path, "\{PackageName}.Architecture::from_json: expected object"),
    )
  }
  let input_modalities : Array[String] = {
    guard json.get("input_modalities") is Some(input_modalities_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("input_modalities"),
          "\{PackageName}.Architecture::from_json: missing field input_modalities",
        ),
      )
    }
    @json.from_json(
      input_modalities_json,
      path=path.add_key("input_modalities"),
    )
  }
  let output_modalities : Array[String] = {
    guard json.get("output_modalities") is Some(output_modalities_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("output_modalities"),
          "\{PackageName}.Architecture::from_json: missing field output_modalities",
        ),
      )
    }
    @json.from_json(
      output_modalities_json,
      path=path.add_key("output_modalities"),
    )
  }
  let tokenizer : String = {
    guard json.get("tokenizer") is Some(tokenizer_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("tokenizer"),
          "\{PackageName}.Architecture::from_json: missing field tokenizer",
        ),
      )
    }
    @json.from_json(tokenizer_json, path=path.add_key("tokenizer"))
  }
  let instruct_type : String? = match json.get("instruct_type") {
    Some(Null) => None
    Some(instruct_type_json) =>
      Some(
        @json.from_json(instruct_type_json, path=path.add_key("instruct_type")),
      )
    None => None
  }
  Architecture::{
    input_modalities,
    output_modalities,
    tokenizer,
    instruct_type,
  }
}

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
pub struct TopProvider {
  context_length : Int?
  max_completion_tokens : Int?
  is_moderated : Bool
} derive(ToJson)

///|
pub impl @json.FromJson for TopProvider with from_json(
  json : Json,
  path : @json.JsonPath,
) -> TopProvider raise @json.JsonDecodeError {
  guard json is @json.Object(json) else {
    raise @json.JsonDecodeError(
      (path, "\{PackageName}.TopProvider::from_json: expected object"),
    )
  }
  let context_length : Int? = match json.get("context_length") {
    Some(Null) => None
    Some(context_length_json) =>
      Some(
        @json.from_json(
          context_length_json,
          path=path.add_key("context_length"),
        ),
      )
    None => None
  }
  let max_completion_tokens : Int? = match json.get("max_completion_tokens") {
    Some(Null) => None
    Some(max_completion_tokens_json) =>
      Some(
        @json.from_json(
          max_completion_tokens_json,
          path=path.add_key("max_completion_tokens"),
        ),
      )
    None => None
  }
  let is_moderated : Bool = {
    guard json.get("is_moderated") is Some(is_moderated_json) else {
      raise @json.JsonDecodeError(
        (
          path.add_key("is_moderated"),
          "\{PackageName}.TopProvider::from_json: missing field is_moderated",
        ),
      )
    }
    @json.from_json(is_moderated_json, path=path.add_key("is_moderated"))
  }
  TopProvider::{ context_length, max_completion_tokens, is_moderated }
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
