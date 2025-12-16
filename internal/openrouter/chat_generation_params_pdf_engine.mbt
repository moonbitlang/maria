///|
enum ChatGenerationParamsPdfEngine {
  MistralOcr
  PdfText
  Native
}

///|
pub impl ToJson for ChatGenerationParamsPdfEngine with to_json(
  self : ChatGenerationParamsPdfEngine,
) -> Json {
  match self {
    MistralOcr => "mistral_ocr"
    PdfText => "pdf_text"
    Native => "native"
  }
}

///|
pub impl @json.FromJson for ChatGenerationParamsPdfEngine with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsPdfEngine raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsPdfEngine::from_json"
  guard json is String(s) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect string"))
  }
  match s {
    "mistral_ocr" => ChatGenerationParamsPdfEngine::MistralOcr
    "pdf_text" => ChatGenerationParamsPdfEngine::PdfText
    "native" => ChatGenerationParamsPdfEngine::Native
    _ =>
      raise @json.JsonDecodeError(
        (path, "\{func_name}: invalid value \"\{s}\""),
      )
  }
}
