
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
