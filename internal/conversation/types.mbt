///|
struct Conversation {
  name : String?
  description : String?
  id : String
  mut system_prompt : String?
  messages : Array[Message]
  created_at : Int64
  mut updated_at : Int64
  cwd : StringView?
}

///|
pub struct Message {
  id : @uuid.Uuid
  /// The Unix timestamp (in seconds) of when the message was created.
  timestamp : Int64
  /// Usage statistics for the completion request.
  usage : @ai.Usage?
  /// The actual message content.
  message : @ai.Message
  /// Whether this message was generated with web search enabled.
  web_search : Bool
}
