///|
pub struct OpenRouter {
  chat : ChatService
  models : ModelsService
}

///|
pub fn OpenRouter::new(
  base_url? : String = BaseUrl,
  api_key~ : String,
) -> OpenRouter {
  let client = Client::new(base_url~, api_key~)
  OpenRouter::{
    chat: ChatService::new(client),
    models: ModelsService::new(client),
  }
}

///|
const PackageName = "@moonbitlang/maria/internal/openrouter"
