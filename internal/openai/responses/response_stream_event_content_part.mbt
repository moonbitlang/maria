///|
/// Reasoning text from the model.
struct ResponseContentPartAddedEventPartReasoningText {
  /// The reasoning text from the model.
  text : String
}

///|
pub impl ToJson for ResponseContentPartAddedEventPartReasoningText with to_json(
  self : ResponseContentPartAddedEventPartReasoningText,
) -> Json {
  { "type": "reasoning_text", "text": self.text }
}

///|
pub impl @json.FromJson for ResponseContentPartAddedEventPartReasoningText with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseContentPartAddedEventPartReasoningText raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let text : String = object.required("text", path~)
  let _ : String = object.required("type", path~)
  ResponseContentPartAddedEventPartReasoningText::{ text, }
}

///|
enum ResponseContentPartAddedEventPart {
  OutputText(ResponseOutputText)
  Refusal(ResponseOutputRefusal)
  ReasoningText(ResponseContentPartAddedEventPartReasoningText)
}

///|
pub impl ToJson for ResponseContentPartAddedEventPart with to_json(
  self : ResponseContentPartAddedEventPart,
) -> Json {
  match self {
    OutputText(part) => part.to_json()
    Refusal(part) => part.to_json()
    ReasoningText(part) => part.to_json()
  }
}

///|
pub impl @json.FromJson for ResponseContentPartAddedEventPart with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseContentPartAddedEventPart raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let type_str : String = object.required("type", path~)
  match type_str {
    "output_text" => OutputText(@json.from_json(json, path~))
    "refusal" => Refusal(@json.from_json(json, path~))
    "reasoning_text" => ReasoningText(@json.from_json(json, path~))
    _ =>
      raise @json.JsonDecodeError(
        (
          path.add_key("type"),
          "ResponseContentPartAddedEventPart: invalid type '\{type_str}'",
        ),
      )
  }
}

///|
type ResponseContentPartDoneEventPart = ResponseContentPartAddedEventPart

///|
struct ResponseContentPartAddedEvent {
  /// The index of the content part that was added.
  content_index : Int64
  /// The ID of the output item that the content part was added to.
  item_id : String
  /// The index of the output item that the content part was added to.
  output_index : Int64
  /// The content part that was added.
  part : ResponseContentPartAddedEventPart
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseContentPartAddedEvent with to_json(
  self : ResponseContentPartAddedEvent,
) -> Json {
  {
    "type": "response.content_part.added",
    "content_index": @jsonx.int64(self.content_index),
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "part": self.part,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseContentPartAddedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseContentPartAddedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let part : ResponseContentPartAddedEventPart = object.required("part", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseContentPartAddedEvent::{
    content_index,
    item_id,
    output_index,
    part,
    sequence_number,
  }
}

///|
struct ResponseContentPartDoneEvent {
  /// The index of the content part that is done.
  content_index : Int64
  /// The ID of the output item that the content part was added to.
  item_id : String
  /// The index of the output item that the content part was added to.
  output_index : Int64
  /// The content part that is done.
  part : ResponseContentPartDoneEventPart
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseContentPartDoneEvent with to_json(
  self : ResponseContentPartDoneEvent,
) -> Json {
  {
    "type": "response.content_part.done",
    "content_index": @jsonx.int64(self.content_index),
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "part": self.part,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseContentPartDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseContentPartDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let part : ResponseContentPartDoneEventPart = object.required("part", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseContentPartDoneEvent::{
    content_index,
    item_id,
    output_index,
    part,
    sequence_number,
  }
}
