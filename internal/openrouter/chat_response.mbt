///|
struct ChatResponse {
  id : String
  choices : Array[ChatResponseChoice]
  created : Int
  model : String
  object : String
  system_fingerprint : String?
  usage : ChatGenerationTokenUsage?
}
