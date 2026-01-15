///|
/// The summary part that was added.
struct ResponseReasoningSummaryPartAddedEventPart {
  /// The text of the summary part.
  text : String
}

///|
pub impl ToJson for ResponseReasoningSummaryPartAddedEventPart with to_json(
  self : ResponseReasoningSummaryPartAddedEventPart,
) -> Json {
  { "type": "summary_text", "text": self.text }
}

///|
pub impl @json.FromJson for ResponseReasoningSummaryPartAddedEventPart with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningSummaryPartAddedEventPart raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseReasoningSummaryPartAddedEventPart::{ text, }
}

///|
/// The completed summary part.
struct ResponseReasoningSummaryPartDoneEventPart {
  /// The text of the summary part.
  text : String
}

///|
pub impl ToJson for ResponseReasoningSummaryPartDoneEventPart with to_json(
  self : ResponseReasoningSummaryPartDoneEventPart,
) -> Json {
  { "type": "summary_text", "text": self.text }
}

///|
pub impl @json.FromJson for ResponseReasoningSummaryPartDoneEventPart with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningSummaryPartDoneEventPart raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseReasoningSummaryPartDoneEventPart::{ text, }
}

///|
struct ResponseReasoningSummaryPartAddedEvent {
  /// The ID of the item this summary part is associated with.
  item_id : String
  /// The index of the output item this summary part is associated with.
  output_index : Int64
  /// The summary part that was added.
  part : ResponseReasoningSummaryPartAddedEventPart
  /// The sequence number of this event.
  sequence_number : Int64
  /// The index of the summary part within the reasoning summary.
  summary_index : Int64
}

///|
pub impl ToJson for ResponseReasoningSummaryPartAddedEvent with to_json(
  self : ResponseReasoningSummaryPartAddedEvent,
) -> Json {
  {
    "type": "response.reasoning_summary_part.added",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "part": self.part,
    "sequence_number": @jsonx.int64(self.sequence_number),
    "summary_index": @jsonx.int64(self.summary_index),
  }
}

///|
pub impl @json.FromJson for ResponseReasoningSummaryPartAddedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningSummaryPartAddedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let part : ResponseReasoningSummaryPartAddedEventPart = object.required(
    "part",
    path~,
  )
  let sequence_number = object.required_int64("sequence_number", path~)
  let summary_index = object.required_int64("summary_index", path~)
  ResponseReasoningSummaryPartAddedEvent::{
    item_id,
    output_index,
    part,
    sequence_number,
    summary_index,
  }
}

///|
struct ResponseReasoningSummaryPartDoneEvent {
  /// The ID of the item this summary part is associated with.
  item_id : String
  /// The index of the output item this summary part is associated with.
  output_index : Int64
  /// The completed summary part.
  part : ResponseReasoningSummaryPartDoneEventPart
  /// The sequence number of this event.
  sequence_number : Int64
  /// The index of the summary part within the reasoning summary.
  summary_index : Int64
}

///|
pub impl ToJson for ResponseReasoningSummaryPartDoneEvent with to_json(
  self : ResponseReasoningSummaryPartDoneEvent,
) -> Json {
  {
    "type": "response.reasoning_summary_part.done",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "part": self.part,
    "sequence_number": @jsonx.int64(self.sequence_number),
    "summary_index": @jsonx.int64(self.summary_index),
  }
}

///|
pub impl @json.FromJson for ResponseReasoningSummaryPartDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningSummaryPartDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let part : ResponseReasoningSummaryPartDoneEventPart = object.required(
    "part",
    path~,
  )
  let sequence_number = object.required_int64("sequence_number", path~)
  let summary_index = object.required_int64("summary_index", path~)
  ResponseReasoningSummaryPartDoneEvent::{
    item_id,
    output_index,
    part,
    sequence_number,
    summary_index,
  }
}

///|
struct ResponseReasoningSummaryTextDeltaEvent {
  /// The text delta that was added to the summary.
  delta : String
  /// The ID of the item this summary text delta is associated with.
  item_id : String
  /// The index of the output item this summary text delta is associated with.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
  /// The index of the summary part within the reasoning summary.
  summary_index : Int64
}

///|
pub impl ToJson for ResponseReasoningSummaryTextDeltaEvent with to_json(
  self : ResponseReasoningSummaryTextDeltaEvent,
) -> Json {
  {
    "type": "response.reasoning_summary_text.delta",
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
    "summary_index": @jsonx.int64(self.summary_index),
  }
}

///|
pub impl @json.FromJson for ResponseReasoningSummaryTextDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningSummaryTextDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  let summary_index = object.required_int64("summary_index", path~)
  ResponseReasoningSummaryTextDeltaEvent::{
    delta,
    item_id,
    output_index,
    sequence_number,
    summary_index,
  }
}

///|
struct ResponseReasoningSummaryTextDoneEvent {
  /// The ID of the item this summary text is associated with.
  item_id : String
  /// The index of the output item this summary text is associated with.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
  /// The index of the summary part within the reasoning summary.
  summary_index : Int64
  /// The full text of the completed reasoning summary.
  text : String
}

///|
pub impl ToJson for ResponseReasoningSummaryTextDoneEvent with to_json(
  self : ResponseReasoningSummaryTextDoneEvent,
) -> Json {
  {
    "type": "response.reasoning_summary_text.done",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
    "summary_index": @jsonx.int64(self.summary_index),
    "text": self.text,
  }
}

///|
pub impl @json.FromJson for ResponseReasoningSummaryTextDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningSummaryTextDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  let summary_index = object.required_int64("summary_index", path~)
  let text : String = object.required("text", path~)
  ResponseReasoningSummaryTextDoneEvent::{
    item_id,
    output_index,
    sequence_number,
    summary_index,
    text,
  }
}

///|
struct ResponseReasoningTextDeltaEvent {
  /// The index of the reasoning content part this delta is associated with.
  content_index : Int64
  /// The text delta that was added to the reasoning content.
  delta : String
  /// The ID of the item this reasoning text delta is associated with.
  item_id : String
  /// The index of the output item this reasoning text delta is associated with.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseReasoningTextDeltaEvent with to_json(
  self : ResponseReasoningTextDeltaEvent,
) -> Json {
  {
    "type": "response.reasoning_text.delta",
    "content_index": @jsonx.int64(self.content_index),
    "delta": self.delta,
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseReasoningTextDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningTextDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseReasoningTextDeltaEvent::{
    content_index,
    delta,
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseReasoningTextDoneEvent {
  /// The index of the reasoning content part.
  content_index : Int64
  /// The ID of the item this reasoning text is associated with.
  item_id : String
  /// The index of the output item this reasoning text is associated with.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
  /// The full text of the completed reasoning content.
  text : String
}

///|
pub impl ToJson for ResponseReasoningTextDoneEvent with to_json(
  self : ResponseReasoningTextDoneEvent,
) -> Json {
  {
    "type": "response.reasoning_text.done",
    "content_index": @jsonx.int64(self.content_index),
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
    "text": self.text,
  }
}

///|
pub impl @json.FromJson for ResponseReasoningTextDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseReasoningTextDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  let text : String = object.required("text", path~)
  ResponseReasoningTextDoneEvent::{
    content_index,
    item_id,
    output_index,
    sequence_number,
    text,
  }
}
