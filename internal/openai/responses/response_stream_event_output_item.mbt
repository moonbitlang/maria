///|
pub struct ResponseOutputItemDoneEvent {
  /// The output item that was marked done.
  item : ResponseOutputItem
  /// The index of the output item that was marked done.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseOutputItemDoneEvent with to_json(
  self : ResponseOutputItemDoneEvent,
) -> Json {
  {
    "type": "response.output_item.done",
    "item": self.item,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseOutputItemDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item : ResponseOutputItem = object.required("item", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseOutputItemDoneEvent::{ item, output_index, sequence_number }
}

///|
struct ResponseOutputItemAddedEvent {
  /// The output item that was added.
  item : ResponseOutputItem
  /// The index of the output item that was added.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseOutputItemAddedEvent with to_json(
  self : ResponseOutputItemAddedEvent,
) -> Json {
  {
    "type": "response.output_item.added",
    "item": self.item,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseOutputItemAddedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputItemAddedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item : ResponseOutputItem = object.required("item", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseOutputItemAddedEvent::{ item, output_index, sequence_number }
}
