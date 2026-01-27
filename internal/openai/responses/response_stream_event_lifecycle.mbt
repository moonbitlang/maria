///|
struct ResponseCreatedEvent {
  /// The response that was created.
  response : Response
  /// The sequence number for this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCreatedEvent with to_json(
  self : ResponseCreatedEvent,
) -> Json {
  {
    "type": "response.created",
    "response": self.response,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCreatedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCreatedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let response : Response = object.required("response", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCreatedEvent::{ response, sequence_number }
}

///|
struct ResponseCompletedEvent {
  /// Properties of the completed response.
  response : Response
  /// The sequence number for this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseCompletedEvent with to_json(
  self : ResponseCompletedEvent,
) -> Json {
  {
    "type": "response.completed",
    "response": self.response,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseCompletedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseCompletedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let response : Response = object.required("response", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseCompletedEvent::{ response, sequence_number }
}

///|
struct ResponseInProgressEvent {
  /// The response that is in progress.
  response : Response
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseInProgressEvent with to_json(
  self : ResponseInProgressEvent,
) -> Json {
  {
    "type": "response.in_progress",
    "response": self.response,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseInProgressEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseInProgressEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let response : Response = object.required("response", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseInProgressEvent::{ response, sequence_number }
}

///|
struct ResponseFailedEvent {
  /// The response that failed.
  response : Response
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseFailedEvent with to_json(self : ResponseFailedEvent) -> Json {
  {
    "type": "response.failed",
    "response": self.response,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseFailedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseFailedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let response : Response = object.required("response", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseFailedEvent::{ response, sequence_number }
}

///|
struct ResponseIncompleteEvent {
  /// The response that was incomplete.
  response : Response
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseIncompleteEvent with to_json(
  self : ResponseIncompleteEvent,
) -> Json {
  {
    "type": "response.incomplete",
    "response": self.response,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseIncompleteEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseIncompleteEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let response : Response = object.required("response", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseIncompleteEvent::{ response, sequence_number }
}

///|
struct ResponseQueuedEvent {
  /// The full response object that is queued.
  response : Response
  /// The sequence number for this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseQueuedEvent with to_json(self : ResponseQueuedEvent) -> Json {
  {
    "type": "response.queued",
    "response": self.response,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseQueuedEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseQueuedEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let response : Response = object.required("response", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseQueuedEvent::{ response, sequence_number }
}
