///|
struct ResponseCodeInterpreterCallCodeDeltaEvent {
  /// The partial code snippet being streamed by the code interpreter.
  delta : String
  /// The unique identifier of the code interpreter tool call item.
  item_id : String
  /// The index of the output item in the response for which the code is being streamed.
  output_index : Int64
  /// The sequence number of this event, used to order streaming events.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCodeInterpreterCallCodeDeltaEvent with to_json(
  self : ResponseCodeInterpreterCallCodeDeltaEvent,
) -> Json {
  {
    "type": "response.code_interpreter_call_code.delta",
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCodeInterpreterCallCodeDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCodeInterpreterCallCodeDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCodeInterpreterCallCodeDeltaEvent::{
    delta,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseCodeInterpreterCallCodeDoneEvent {
  /// The final code snippet output by the code interpreter.
  code : String
  /// The unique identifier of the code interpreter tool call item.
  item_id : String
  /// The index of the output item in the response for which the code is finalized.
  output_index : Int64
  /// The sequence number of this event, used to order streaming events.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCodeInterpreterCallCodeDoneEvent with to_json(
  self : ResponseCodeInterpreterCallCodeDoneEvent,
) -> Json {
  {
    "type": "response.code_interpreter_call_code.done",
    "code": self.code,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCodeInterpreterCallCodeDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCodeInterpreterCallCodeDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let code : String = object.required("code", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCodeInterpreterCallCodeDoneEvent::{
    code,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseCodeInterpreterCallCompletedEvent {
  /// The unique identifier of the code interpreter tool call item.
  item_id : String
  /// The index of the output item in the response for which the code interpreter call is completed.
  output_index : Int64
  /// The sequence number of this event, used to order streaming events.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCodeInterpreterCallCompletedEvent with to_json(
  self : ResponseCodeInterpreterCallCompletedEvent,
) -> Json {
  {
    "type": "response.code_interpreter_call.completed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCodeInterpreterCallCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCodeInterpreterCallCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCodeInterpreterCallCompletedEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseCodeInterpreterCallInProgressEvent {
  /// The unique identifier of the code interpreter tool call item.
  item_id : String
  /// The index of the output item in the response for which the code interpreter call is in progress.
  output_index : Int64
  /// The sequence number of this event, used to order streaming events.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCodeInterpreterCallInProgressEvent with to_json(
  self : ResponseCodeInterpreterCallInProgressEvent,
) -> Json {
  {
    "type": "response.code_interpreter_call.in_progress",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCodeInterpreterCallInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCodeInterpreterCallInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCodeInterpreterCallInProgressEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseCodeInterpreterCallInterpretingEvent {
  /// The unique identifier of the code interpreter tool call item.
  item_id : String
  /// The index of the output item in the response for which the code interpreter is interpreting code.
  output_index : Int64
  /// The sequence number of this event, used to order streaming events.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCodeInterpreterCallInterpretingEvent with to_json(
  self : ResponseCodeInterpreterCallInterpretingEvent,
) -> Json {
  {
    "type": "response.code_interpreter_call.interpreting",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCodeInterpreterCallInterpretingEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCodeInterpreterCallInterpretingEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCodeInterpreterCallInterpretingEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}
