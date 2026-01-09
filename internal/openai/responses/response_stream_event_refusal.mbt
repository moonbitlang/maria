///|
struct ResponseRefusalDeltaEvent {
  /// The index of the content part that the refusal text is added to.
  content_index : Int64
  /// The refusal text that is added.
  delta : String
  /// The ID of the output item that the refusal text is added to.
  item_id : String
  /// The index of the output item that the refusal text is added to.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseRefusalDeltaEvent with to_json(
  self : ResponseRefusalDeltaEvent,
) -> Json {
  {
    "type": "response.refusal.delta",
    "content_index": @jsonx.int64(self.content_index),
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseRefusalDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseRefusalDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseRefusalDeltaEvent::{
    content_index,
    delta,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseRefusalDoneEvent {
  /// The index of the content part that the refusal text is finalized.
  content_index : Int64
  /// The ID of the output item that the refusal text is finalized.
  item_id : String
  /// The index of the output item that the refusal text is finalized.
  output_index : Int64
  /// The refusal text that is finalized.
  refusal : String
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseRefusalDoneEvent with to_json(
  self : ResponseRefusalDoneEvent,
) -> Json {
  {
    "type": "response.refusal.done",
    "content_index": @jsonx.int64(self.content_index),
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "refusal": self.refusal,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseRefusalDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseRefusalDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let refusal : String = object.required("refusal", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseRefusalDoneEvent::{
    content_index,
    item_id,
    output_index,
    refusal,
    sequence_number,
  }
}
