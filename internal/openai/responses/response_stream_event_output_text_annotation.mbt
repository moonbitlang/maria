///|
struct ResponseOutputTextAnnotationAddedEvent {
  /// The annotation object being added.
  annotation : Json
  /// The index of the annotation within the content part.
  annotation_index : Int64
  /// The index of the content part within the output item.
  content_index : Int64
  /// The unique identifier of the item to which the annotation is being added.
  item_id : String
  /// The index of the output item in the response's output array.
  output_index : Int64
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseOutputTextAnnotationAddedEvent with to_json(
  self : ResponseOutputTextAnnotationAddedEvent,
) -> Json {
  {
    "type": "response.output_text.annotation.added",
    "annotation": self.annotation,
    "annotation_index": @jsonx.int64(self.annotation_index),
    "content_index": @jsonx.int64(self.content_index),
    "item_id": self.item_id,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseOutputTextAnnotationAddedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseOutputTextAnnotationAddedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let annotation : Json = object.required("annotation", path~)
  let annotation_index = object.required_int64("annotation_index", path~)
  let content_index = object.required_int64("content_index", path~)
  let item_id : String = object.required("item_id", path~)
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseOutputTextAnnotationAddedEvent::{
    annotation,
    annotation_index,
    content_index,
    item_id,
    output_index,
    sequence_number,
  }
}
