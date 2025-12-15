///|
struct ChatGenerationParamsMaxPrice {
  prompt : BigInt?
  completion : BigInt?
  image : BigInt?
  audio : BigInt?
  request : BigInt?
}

///|
pub impl ToJson for ChatGenerationParamsMaxPrice with to_json(
  self : ChatGenerationParamsMaxPrice,
) -> Json {
  let object : Map[String, Json] = {}
  if self.prompt is Some(prompt) {
    object["prompt"] = prompt.to_json()
  }
  if self.completion is Some(completion) {
    object["completion"] = completion.to_json()
  }
  if self.image is Some(image) {
    object["image"] = image.to_json()
  }
  if self.audio is Some(audio) {
    object["audio"] = audio.to_json()
  }
  if self.request is Some(request) {
    object["request"] = request.to_json()
  }
  Json::object(object)
}
