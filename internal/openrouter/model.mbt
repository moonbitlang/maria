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
  top_provider : TopProviderInfo
  per_request_limits : Json?
  supported_parameters : Array[Parameter]
} derive(ToJson)

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
  let top_provider : TopProviderInfo = {
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
  let supported_parameters : Array[Parameter] = {
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
