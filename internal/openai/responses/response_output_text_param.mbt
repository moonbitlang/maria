///|
/// A text output from the model.
struct ResponseOutputTextParam {
  /// The annotations of the text output.
  annotations : Array[ResponseOutputTextAnnotationParam]
  /// The text output from the model.
  text : String
  /// Log probability information for the output tokens.
  logprobs : Array[ResponseOutputTextLogprobParam]
}

///|
pub impl ToJson for ResponseOutputTextParam with to_json(
  self : ResponseOutputTextParam,
) -> Json {
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
pub impl @json.FromJson for ResponseOutputTextParam with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextParam raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let annotations : Array[ResponseOutputTextAnnotationParam] = object.required(
    "annotations",
    path~,
  )
  let logprobs : Array[ResponseOutputTextLogprobParam] = match
    object.optional("logprobs", path~) {
    None => []
    Some(logprobs) => logprobs
  }
  ResponseOutputTextParam::{ text, annotations, logprobs }
}
