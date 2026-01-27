///|
struct ResponseMcpCallArgumentsDeltaEvent {
  /// A JSON string containing the partial update to the arguments for the MCP tool call.
  delta : String
  /// The unique identifier of the MCP tool call item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpCallArgumentsDeltaEvent with to_json(
  self : ResponseMcpCallArgumentsDeltaEvent,
) -> Json {
  {
    "type": "response.mcp_call_arguments.delta",
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpCallArgumentsDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpCallArgumentsDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpCallArgumentsDeltaEvent::{
    delta,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseMcpCallArgumentsDoneEvent {
  /// A JSON string containing the finalized arguments for the MCP tool call.
  arguments : String
  /// The unique identifier of the MCP tool call item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpCallArgumentsDoneEvent with to_json(
  self : ResponseMcpCallArgumentsDoneEvent,
) -> Json {
  {
    "type": "response.mcp_call_arguments.done",
    "arguments": self.arguments,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpCallArgumentsDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpCallArgumentsDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let arguments : String = object.required("arguments", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpCallArgumentsDoneEvent::{
    arguments,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseMcpCallCompletedEvent {
  /// The ID of the MCP tool call item that completed.
  item_id : String
  /// The index of the output item that completed.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpCallCompletedEvent with to_json(
  self : ResponseMcpCallCompletedEvent,
) -> Json {
  {
    "type": "response.mcp_call.completed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpCallCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpCallCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpCallCompletedEvent::{ item_id, output_index, sequence_number }
}

///|
struct ResponseMcpCallFailedEvent {
  /// The ID of the MCP tool call item that failed.
  item_id : String
  /// The index of the output item that failed.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpCallFailedEvent with to_json(
  self : ResponseMcpCallFailedEvent,
) -> Json {
  {
    "type": "response.mcp_call.failed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpCallFailedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpCallFailedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpCallFailedEvent::{ item_id, output_index, sequence_number }
}

///|
struct ResponseMcpCallInProgressEvent {
  /// The unique identifier of the MCP tool call item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpCallInProgressEvent with to_json(
  self : ResponseMcpCallInProgressEvent,
) -> Json {
  {
    "type": "response.mcp_call.in_progress",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpCallInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpCallInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpCallInProgressEvent::{ item_id, output_index, sequence_number }
}

///|
struct ResponseMcpListToolsCompletedEvent {
  /// The ID of the MCP tool call item that produced this output.
  item_id : String
  /// The index of the output item that was processed.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpListToolsCompletedEvent with to_json(
  self : ResponseMcpListToolsCompletedEvent,
) -> Json {
  {
    "type": "response.mcp_list_tools.completed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpListToolsCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpListToolsCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpListToolsCompletedEvent::{ item_id, output_index, sequence_number }
}

///|
struct ResponseMcpListToolsFailedEvent {
  /// The ID of the MCP tool call item that failed.
  item_id : String
  /// The index of the output item that failed.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpListToolsFailedEvent with to_json(
  self : ResponseMcpListToolsFailedEvent,
) -> Json {
  {
    "type": "response.mcp_list_tools.failed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpListToolsFailedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpListToolsFailedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpListToolsFailedEvent::{ item_id, output_index, sequence_number }
}

///|
struct ResponseMcpListToolsInProgressEvent {
  /// The ID of the MCP tool call item that is being processed.
  item_id : String
  /// The index of the output item that is being processed.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseMcpListToolsInProgressEvent with to_json(
  self : ResponseMcpListToolsInProgressEvent,
) -> Json {
  {
    "type": "response.mcp_list_tools.in_progress",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseMcpListToolsInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseMcpListToolsInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseMcpListToolsInProgressEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}
