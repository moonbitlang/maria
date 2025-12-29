///|
struct ResponseWebSearchCallCompletedEvent {
  /// Unique ID for the output item associated with the web search call.
  item_id : String
  /// The index of the output item that the web search call is associated with.
  output_index : Int64
  /// The sequence number of the web search call being processed.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseWebSearchCallCompletedEvent with to_json(
  self : ResponseWebSearchCallCompletedEvent,
) -> Json {
  {
    "type": "response.web_search_call.completed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseWebSearchCallCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseWebSearchCallCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseWebSearchCallCompletedEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseWebSearchCallInProgressEvent {
  /// Unique ID for the output item associated with the web search call.
  item_id : String
  /// The index of the output item that the web search call is associated with.
  output_index : Int64
  /// The sequence number of the web search call being processed.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseWebSearchCallInProgressEvent with to_json(
  self : ResponseWebSearchCallInProgressEvent,
) -> Json {
  {
    "type": "response.web_search_call.in_progress",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseWebSearchCallInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseWebSearchCallInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseWebSearchCallInProgressEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseWebSearchCallSearchingEvent {
  /// Unique ID for the output item associated with the web search call.
  item_id : String
  /// The index of the output item that the web search call is associated with.
  output_index : Int64
  /// The sequence number of the web search call being processed.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseWebSearchCallSearchingEvent with to_json(
  self : ResponseWebSearchCallSearchingEvent,
) -> Json {
  {
    "type": "response.web_search_call.searching",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseWebSearchCallSearchingEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseWebSearchCallSearchingEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseWebSearchCallSearchingEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}
