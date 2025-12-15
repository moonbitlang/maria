///|
enum ChatGenerationParamsRoute {
  Fallback
  Sort
}

///|
pub impl ToJson for ChatGenerationParamsRoute with to_json(
  self : ChatGenerationParamsRoute,
) -> Json {
  match self {
    Fallback => "fallback"
    Sort => "sort"
  }
}
