///|
priv struct QueuedMessage {
  id : String
  message : Json
} derive(ToJson, @json.FromJson)
