///|
enum ChatGenerationParamsEngine {
  Native
  Exa
}

///|
pub impl ToJson for ChatGenerationParamsEngine with to_json(
  self : ChatGenerationParamsEngine,
) -> Json {
  match self {
    Native => "native"
    Exa => "exa"
  }
}

///|
pub impl @json.FromJson for ChatGenerationParamsEngine with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsEngine raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsEngine::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "native" => ChatGenerationParamsEngine::Native
    "exa" => ChatGenerationParamsEngine::Exa
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
