///|
struct ResponseFileSearchCallCompletedEvent {
  /// The ID of the output item that the file search call is initiated.
  item_id : String
  /// The index of the output item that the file search call is initiated.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseFileSearchCallCompletedEvent with to_json(
  self : ResponseFileSearchCallCompletedEvent,
) -> Json {
  {
    "type": "response.file_search_call.completed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseFileSearchCallCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchCallCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseFileSearchCallCompletedEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseFileSearchCallInProgressEvent {
  /// The ID of the output item that the file search call is initiated.
  item_id : String
  /// The index of the output item that the file search call is initiated.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseFileSearchCallInProgressEvent with to_json(
  self : ResponseFileSearchCallInProgressEvent,
) -> Json {
  {
    "type": "response.file_search_call.in_progress",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseFileSearchCallInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchCallInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseFileSearchCallInProgressEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseFileSearchCallSearchingEvent {
  /// The ID of the output item that the file search call is initiated.
  item_id : String
  /// The index of the output item that the file search call is searching.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseFileSearchCallSearchingEvent with to_json(
  self : ResponseFileSearchCallSearchingEvent,
) -> Json {
  {
    "type": "response.file_search_call.searching",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseFileSearchCallSearchingEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFileSearchCallSearchingEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseFileSearchCallSearchingEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}
