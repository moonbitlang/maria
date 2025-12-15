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
