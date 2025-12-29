///|
pub(all) enum ResponseStreamEvent {
  TextDelta(String)
  OutputItemDone(ResponseItem)
  FunctionCallArgumentsDelta(ResponseFunctionCallArgumentsDeltaEvent)
  Completed
}

///|
pub impl ToJson for ResponseStreamEvent with to_json(self : ResponseStreamEvent) -> Json {
  match self {
    TextDelta(delta) => { "type": "response.output_text.delta", "delta": delta }
    OutputItemDone(item) =>
      { "type": "response.output_item.done", "item": item.to_json() }
    FunctionCallArgumentsDelta(delta) => ...
    Completed => { "type": "response.completed" }
  }
}

///|
pub impl @json.FromJson for ResponseStreamEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseStreamEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "response.output_text.delta" => {
      let delta : String = object.required("delta", path~)
      TextDelta(delta)
    }
    "response.content_part.delta" => {
      let delta_json : Json = object.required("delta", path~)
      let delta_object = @jsonx.as_object(
        delta_json,
        path=path.add_key("delta"),
      )
      let text : String = delta_object.required(
        "text",
        path=path.add_key("delta"),
      )
      TextDelta(text)
    }
    "response.output_item.done" => {
      let item : ResponseItem = object.required("item", path~)
      OutputItemDone(item)
    }
    "response.function_call_arguments.delta" => {
      let delta = @json.from_json(json, path)
      FunctionCallArgumentsDelta(delta)
    }
    "response.completed" => Completed
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseStreamEvent: invalid type '\{type_str}'",
        ),
      )
  }
}
