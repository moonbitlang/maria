///|
struct ResponseFunctionCallArgumentsDeltaEvent {
  /// The function-call arguments delta that is added.
  delta : String
  /// The ID of the output item that the function-call arguments delta is added to.
  item_id : String
  /// The index of the output item that the function-call arguments delta is added to.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseFunctionCallArgumentsDeltaEvent with to_json(
  self : ResponseFunctionCallArgumentsDeltaEvent,
) -> Json {
  {
    "type": "response.function_call_arguments.delta",
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseFunctionCallArgumentsDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionCallArgumentsDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index : Int64 = @jsonx.as_int64(
    object.required("output_index", path~),
    path=path.add_key("output_index"),
  )
  let sequence_number : Int64 = @jsonx.as_int64(
    object.required("sequence_number", path~),
    path=path.add_key("sequence_number"),
  )
  ResponseFunctionCallArgumentsDeltaEvent::{
    delta,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseFunctionCallArgumentsDoneEvent {
  /// The function-call arguments.
  arguments : String
  /// The ID of the item.
  item_id : String
  /// The name of the function that was called.
  name : String
  /// The index of the output item.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseFunctionCallArgumentsDoneEvent with to_json(
  self : ResponseFunctionCallArgumentsDoneEvent,
) -> Json {
  {
    "type": "response.function_call_arguments.done",
    "arguments": self.arguments,
    "item_id": self.item_id,
    "name": self.name,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseFunctionCallArgumentsDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFunctionCallArgumentsDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let arguments : String = object.required("arguments", path~)
  let item_id : String = object.required("item_id", path~)
  let name : String = object.required("name", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseFunctionCallArgumentsDoneEvent::{
    arguments,
    item_id,
    name,
    output_index,
    sequence_number,
  }
}
