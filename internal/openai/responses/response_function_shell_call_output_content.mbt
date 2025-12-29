///|
/// Captured stdout and stderr for a portion of a shell tool call output.
pub struct ResponseFunctionShellCallOutputContent {
  outcome : ResponseFunctionShellCallOutputContentOutcome
  stderr : String
  stdout : String
}

///|
pub enum ResponseFunctionShellCallOutputContentOutcome {
  Timeout(ResponseFunctionShellCallOutputContentOutcomeTimeout)
  Exit(ResponseFunctionShellCallOutputContentOutcomeExit)
}

///|
pub struct ResponseFunctionShellCallOutputContentOutcomeTimeout {}

///|
pub struct ResponseFunctionShellCallOutputContentOutcomeExit {
  exit_code : Int64
}

///|
pub impl ToJson for ResponseFunctionShellCallOutputContentOutcomeTimeout with to_json(
  _ : ResponseFunctionShellCallOutputContentOutcomeTimeout,
) -> Json {
  { "type": "timeout" }
}

///|
pub impl @json.FromJson for ResponseFunctionShellCallOutputContentOutcomeTimeout with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionShellCallOutputContentOutcomeTimeout raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  ResponseFunctionShellCallOutputContentOutcomeTimeout::{  }
}

///|
pub impl ToJson for ResponseFunctionShellCallOutputContentOutcomeExit with to_json(
  self : ResponseFunctionShellCallOutputContentOutcomeExit,
) -> Json {
  { "type": "exit", "exit_code": @jsonx.int64(self.exit_code) }
}

///|
pub impl @json.FromJson for ResponseFunctionShellCallOutputContentOutcomeExit with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionShellCallOutputContentOutcomeExit raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let _ : String = object.required("type", path~)
  let exit_code = object.required_int64("exit_code", path~)
  ResponseFunctionShellCallOutputContentOutcomeExit::{ exit_code, }
}

///|
pub impl ToJson for ResponseFunctionShellCallOutputContentOutcome with to_json(
  self : ResponseFunctionShellCallOutputContentOutcome,
) -> Json {
  match self {
    Timeout(value) => value.to_json()
    Exit(value) => value.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseFunctionShellCallOutputContentOutcome with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionShellCallOutputContentOutcome raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_ : String = object.required("type", path~)
  match type_ {
    "timeout" => Timeout(@json.from_json(json, path~))
    "exit" => Exit(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseFunctionShellCallOutputContentOutcome: invalid type '\{type_}'",
        ),
      )
  }
}

///|
pub impl ToJson for ResponseFunctionShellCallOutputContent with to_json(
  self : ResponseFunctionShellCallOutputContent,
) -> Json {
  { "outcome": self.outcome, "stderr": self.stderr, "stdout": self.stdout }
}

///|
pub impl @json.FromJson for ResponseFunctionShellCallOutputContent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionShellCallOutputContent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let outcome : ResponseFunctionShellCallOutputContentOutcome = object.required(
    "outcome",
    path~,
  )
  let stderr : String = object.required("stderr", path~)
  let stdout : String = object.required("stdout", path~)
  ResponseFunctionShellCallOutputContent::{ outcome, stderr, stdout }
}
