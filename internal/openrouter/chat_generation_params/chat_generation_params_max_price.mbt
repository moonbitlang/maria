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

///|
pub impl @json.FromJson for ChatGenerationParamsMaxPrice with from_json(
  json : Json,
  path : @json.JsonPath,
) -> ChatGenerationParamsMaxPrice raise @json.JsonDecodeError {
  let func_name = "\{PackageName}.ChatGenerationParamsMaxPrice::from_json"
  guard json is Object(object) else {
    raise @json.JsonDecodeError((path, "\{func_name}: expect object"))
  }
  let prompt : BigInt? = match object.get("prompt") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("prompt")))
  }
  let completion : BigInt? = match object.get("completion") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("completion")))
  }
  let image : BigInt? = match object.get("image") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("image")))
  }
  let audio : BigInt? = match object.get("audio") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("audio")))
  }
  let request : BigInt? = match object.get("request") {
    None | Some(Null) => None
    Some(v) => Some(@json.from_json(v, path=path.add_key("request")))
  }
  ChatGenerationParamsMaxPrice::{ prompt, completion, image, audio, request }
}
