///|
struct ResponseImageGenCallCompletedEvent {
  /// The unique identifier of the image generation item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseImageGenCallCompletedEvent with to_json(
  self : ResponseImageGenCallCompletedEvent,
) -> Json {
  {
    "type": "response.image_generation_call.completed",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseImageGenCallCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseImageGenCallCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseImageGenCallCompletedEvent::{ item_id, output_index, sequence_number }
}

///|
struct ResponseImageGenCallGeneratingEvent {
  /// The unique identifier of the image generation item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of the image generation item being processed.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseImageGenCallGeneratingEvent with to_json(
  self : ResponseImageGenCallGeneratingEvent,
) -> Json {
  {
    "type": "response.image_generation_call.generating",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseImageGenCallGeneratingEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseImageGenCallGeneratingEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseImageGenCallGeneratingEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseImageGenCallInProgressEvent {
  /// The unique identifier of the image generation item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of the image generation item being processed.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseImageGenCallInProgressEvent with to_json(
  self : ResponseImageGenCallInProgressEvent,
) -> Json {
  {
    "type": "response.image_generation_call.in_progress",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseImageGenCallInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseImageGenCallInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseImageGenCallInProgressEvent::{
    item_id,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseImageGenCallPartialImageEvent {
  /// The unique identifier of the image generation item being processed.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// Base64-encoded partial image data, suitable for rendering as an image.
  partial_image_b64 : String
  /// 0-based index for the partial image.
  partial_image_index : Int64
  /// The sequence number of the image generation item being processed.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseImageGenCallPartialImageEvent with to_json(
  self : ResponseImageGenCallPartialImageEvent,
) -> Json {
  {
    "type": "response.image_generation_call.partial_image",
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "partial_image_b64": self.partial_image_b64,
    "partial_image_index": @jsonx.int64(self.partial_image_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseImageGenCallPartialImageEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseImageGenCallPartialImageEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let partial_image_b64 : String = object.required("partial_image_b64", path~)
  let partial_image_index = object.required_int64("partial_image_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseImageGenCallPartialImageEvent::{
    item_id,
    output_index,
    partial_image_b64,
    partial_image_index,
    sequence_number,
  }
}
