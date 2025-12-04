///|
struct Conversation {
  clock : &@clock.Clock
  name : String
  description : String?
  id : String
  mut system_prompt : String?
  messages : Array[Message]
  created_at : Int64
  mut updated_at : Int64
}

///|
priv struct Message {
  /// The Unix timestamp (in seconds) of when the message was created.
  timestamp : Int64
  /// Usage statistics for the completion request.
  usage : @ai.Usage?
  message : @ai.Message
}
