///|
struct ResponseCustomToolCallInputDeltaEvent {
  /// The incremental input data (delta) for the custom tool call.
  delta : String
  /// Unique identifier for the API item associated with this event.
  item_id : String
  /// The index of the output this delta applies to.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCustomToolCallInputDeltaEvent with to_json(
  self : ResponseCustomToolCallInputDeltaEvent,
) -> Json {
  {
    "type": "response.custom_tool_call_input.delta",
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCustomToolCallInputDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCustomToolCallInputDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCustomToolCallInputDeltaEvent::{
    delta,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseCustomToolCallInputDoneEvent {
  /// The complete input data for the custom tool call.
  input : String
  /// Unique identifier for the API item associated with this event.
  item_id : String
  /// The index of the output this event applies to.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCustomToolCallInputDoneEvent with to_json(
  self : ResponseCustomToolCallInputDoneEvent,
) -> Json {
  {
    "type": "response.custom_tool_call_input.done",
    "input": self.input,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCustomToolCallInputDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCustomToolCallInputDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let input : String = object.required("input", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCustomToolCallInputDoneEvent::{
    input,
    item_id,
    output_index,
    sequence_number,
  }
}
