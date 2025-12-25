///|
struct ModelsService {
  client : Client
}

///|
fn ModelsService::new(client : Client) -> ModelsService {
  ModelsService::{ client, }
}

///|
pub async fn ModelsService::list(self : ModelsService) -> Array[Model] {
  let (r, b) = self.client.get("/models")
  guard b is { "data": data_json, .. } else { raise InvalidResponse(r, b) }
  @json.from_json(data_json)
}

///|
pub async fn ModelsService::count(self : ModelsService) -> Int {
  let (r, b) = self.client.get("/models/count")
  guard b is { "data": { "count": count_json, .. }, .. } else {
    raise InvalidResponse(r, b)
  }
  @json.from_json(count_json)
}
