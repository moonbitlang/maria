///|
struct ChatGenerationParams {
  provider : ChatGenerationParamsProvider?
  plugins : Array[ChatGenerationParamsPlugin]?
  route : ChatGenerationParamsRoute?
  user : String?
  session_id : String?
  messages : Array[Message]
  model : String?
  models : Array[String]?
  frequency_penalty : Float?
  logit_bias : Map[String, Float]?
  logprobs : Bool?
  top_logprobs : Int?
  max_completion_tokens : Int?
  max_tokens : Int?
  metadata : Map[String, String]?
  presence_penalty : Float?
  reasoning : Reasoning?
  response_format : ChatGenerationParamsResponseFormat?
  seed : Int?
  stop : Array[String]?
  stream : Bool
  stream_options : ChatStreamOptions?
  temperature : Float?
  tool_choice : Json?
  tools : Array[ToolDefinitionJson]?
  top_p : Float?
  debug : Debug?
}
