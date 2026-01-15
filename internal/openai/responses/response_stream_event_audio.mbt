///|
struct ResponseAudioDeltaEvent {
  /// A chunk of Base64 encoded response audio bytes.
  delta : String
  /// A sequence number for this chunk of the stream response.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseAudioDeltaEvent with to_json(
  self : ResponseAudioDeltaEvent,
) -> Json {
  {
    "type": "response.audio.delta",
    "delta": self.delta,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseAudioDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseAudioDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseAudioDeltaEvent::{ delta, sequence_number }
}

///|
struct ResponseAudioDoneEvent {
  /// The sequence number of the delta.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseAudioDoneEvent with to_json(
  self : ResponseAudioDoneEvent,
) -> Json {
  {
    "type": "response.audio.done",
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseAudioDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseAudioDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseAudioDoneEvent::{ sequence_number, }
}

///|
struct ResponseAudioTranscriptDeltaEvent {
  /// The partial transcript of the audio response.
  delta : String
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseAudioTranscriptDeltaEvent with to_json(
  self : ResponseAudioTranscriptDeltaEvent,
) -> Json {
  {
    "type": "response.audio.transcript.delta",
    "delta": self.delta,
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseAudioTranscriptDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseAudioTranscriptDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let delta : String = object.required("delta", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseAudioTranscriptDeltaEvent::{ delta, sequence_number }
}

///|
struct ResponseAudioTranscriptDoneEvent {
  /// The sequence number of this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseAudioTranscriptDoneEvent with to_json(
  self : ResponseAudioTranscriptDoneEvent,
) -> Json {
  {
    "type": "response.audio.transcript.done",
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseAudioTranscriptDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseAudioTranscriptDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseAudioTranscriptDoneEvent::{ sequence_number, }
}
