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
