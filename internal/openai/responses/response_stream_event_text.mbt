///|
/// The log probability of a token in a text delta.
struct ResponseTextDeltaEventLogprob {
  /// A possible text token.
  token : String
  /// The log probability of this token.
  logprob : Double
  /// The log probability of the top 20 most likely tokens.
  top_logprobs : Array[ResponseTextDeltaEventLogprobTopLogprob]
}

///|
pub impl ToJson for ResponseTextDeltaEventLogprob with to_json(
  self : ResponseTextDeltaEventLogprob,
) -> Json {
  {
    "token": self.token,
    "logprob": self.logprob,
    "top_logprobs": self.top_logprobs,
  }
}

///|
pub impl @json.FromJson for ResponseTextDeltaEventLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextDeltaEventLogprob raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let token : String = object.required("token", path~)
  let logprob : Double = object.required("logprob", path~)
  let top_logprobs : Array[ResponseTextDeltaEventLogprobTopLogprob] = object.required(
    "top_logprobs",
    path~,
  )
  ResponseTextDeltaEventLogprob::{ token, logprob, top_logprobs }
}

///|
struct ResponseTextDeltaEventLogprobTopLogprob {
  /// A possible text token.
  token : String
  /// The log probability of this token.
  logprob : Double
}

///|
pub impl ToJson for ResponseTextDeltaEventLogprobTopLogprob with to_json(
  self : ResponseTextDeltaEventLogprobTopLogprob,
) -> Json {
  { "token": self.token, "logprob": self.logprob }
}

///|
pub impl @json.FromJson for ResponseTextDeltaEventLogprobTopLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextDeltaEventLogprobTopLogprob raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let token : String = object.required("token", path~)
  let logprob : Double = object.required("logprob", path~)
  ResponseTextDeltaEventLogprobTopLogprob::{ token, logprob }
}

///|
/// The log probability of a token in a text done event.
struct ResponseTextDoneEventLogprob {
  /// A possible text token.
  token : String
  /// The log probability of this token.
  logprob : Double
  /// The log probability of the top 20 most likely tokens.
  top_logprobs : Array[ResponseTextDoneEventLogprobTopLogprob]
}

///|
pub impl ToJson for ResponseTextDoneEventLogprob with to_json(
  self : ResponseTextDoneEventLogprob,
) -> Json {
  {
    "token": self.token,
    "logprob": self.logprob,
    "top_logprobs": self.top_logprobs,
  }
}

///|
pub impl @json.FromJson for ResponseTextDoneEventLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextDoneEventLogprob raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let token : String = object.required("token", path~)
  let logprob : Double = object.required("logprob", path~)
  let top_logprobs : Array[ResponseTextDoneEventLogprobTopLogprob] = object.required(
    "top_logprobs",
    path~,
  )
  ResponseTextDoneEventLogprob::{ token, logprob, top_logprobs }
}

///|
struct ResponseTextDoneEventLogprobTopLogprob {
  /// A possible text token.
  token : String
  /// The log probability of this token.
  logprob : Double
}

///|
pub impl ToJson for ResponseTextDoneEventLogprobTopLogprob with to_json(
  self : ResponseTextDoneEventLogprobTopLogprob,
) -> Json {
  { "token": self.token, "logprob": self.logprob }
}

///|
pub impl @json.FromJson for ResponseTextDoneEventLogprobTopLogprob with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextDoneEventLogprobTopLogprob raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let token : String = object.required("token", path~)
  let logprob : Double = object.required("logprob", path~)
  ResponseTextDoneEventLogprobTopLogprob::{ token, logprob }
}

///|
pub struct ResponseTextDeltaEvent {
  /// The index of the content part that the text delta was added to.
  content_index : Int64
  /// The text delta that was added.
  delta : String
  /// The ID of the output item that the text delta was added to.
  item_id : String
  /// The log probabilities of the tokens in the delta.
  logprobs : Array[ResponseTextDeltaEventLogprob]
  /// The index of the output item that the text delta was added to.
  output_index : Int64
  /// The sequence number for this event.
  sequence_number : Int64
}

///|
pub impl ToJson for ResponseTextDeltaEvent with to_json(
  self : ResponseTextDeltaEvent,
) -> Json {
  {
    "type": "response.output_text.delta",
    "content_index": @jsonx.int64(self.content_index),
    "delta": self.delta,
    "item_id": self.item_id,
    "logprobs": self.logprobs,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
  }
}

///|
pub impl @json.FromJson for ResponseTextDeltaEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextDeltaEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let delta : String = object.required("delta", path~)
  let item_id : String = object.required("item_id", path~)
  let logprobs : Array[ResponseTextDeltaEventLogprob] = object.required(
    "logprobs",
    path~,
  )
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  ResponseTextDeltaEvent::{
    content_index,
    delta,
    item_id,
    logprobs,
    output_index,
    sequence_number,
  }
}

///|
struct ResponseTextDoneEvent {
  /// The index of the content part that the text content is finalized.
  content_index : Int64
  /// The ID of the output item that the text content is finalized.
  item_id : String
  /// The log probabilities of the tokens in the delta.
  logprobs : Array[ResponseTextDoneEventLogprob]
  /// The index of the output item that the text content is finalized.
  output_index : Int64
  /// The sequence number for this event.
  sequence_number : Int64
  /// The text content that is finalized.
  text : String
}

///|
pub impl ToJson for ResponseTextDoneEvent with to_json(
  self : ResponseTextDoneEvent,
) -> Json {
  {
    "type": "response.output_text.done",
    "content_index": @jsonx.int64(self.content_index),
    "item_id": self.item_id,
    "logprobs": self.logprobs,
    "output_index": @jsonx.int64(self.output_index),
    "sequence_number": @jsonx.int64(self.sequence_number),
    "text": self.text,
  }
}

///|
pub impl @json.FromJson for ResponseTextDoneEvent with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ResponseTextDoneEvent raise @json.JsonDecodeError {
  let object = @jsonx.as_object(json, path~)
  let content_index = object.required_int64("content_index", path~)
  let item_id : String = object.required("item_id", path~)
  let logprobs : Array[ResponseTextDoneEventLogprob] = object.required(
    "logprobs",
    path~,
  )
  let output_index = object.required_int64("output_index", path~)
  let sequence_number = object.required_int64("sequence_number", path~)
  let text : String = object.required("text", path~)
  ResponseTextDoneEvent::{
    content_index,
    item_id,
    logprobs,
    output_index,
    sequence_number,
    text,
  }
}
