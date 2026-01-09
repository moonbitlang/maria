///|
/// A text output from the model.
pub struct ResponseOutputText {
  /// The annotations of the text output.
  annotations : Array[ResponseOutputTextAnnotation]
  /// The text output from the model.
  text : String
  /// Log probability information for the output tokens.
  logprobs : Array[ResponseOutputTextLogprob]
}

///|
pub impl ToJson for ResponseOutputText with to_json(self : ResponseOutputText) -> Json {
  let obj : Map[String, Json] = {
    "type": "output_text",
    "text": self.text,
    "annotations": self.annotations,
  }
  if !self.logprobs.is_empty() {
    obj["logprobs"] = self.logprobs.to_json()
  }
  Json::object(obj)
}

///|
pub impl @json.FromJson for ResponseOutputText with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputText raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let annotations : Array[ResponseOutputTextAnnotation] = object.required(
    "annotations",
    path~,
  )
  let logprobs : Array[ResponseOutputTextLogprob] = match
    object.optional("logprobs", path~) {
    None => []
    Some(logprobs) => logprobs
  }
  ResponseOutputText::{ text, annotations, logprobs }
}
