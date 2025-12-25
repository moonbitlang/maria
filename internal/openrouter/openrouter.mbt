///|
pub struct OpenRouter {
  priv client : Client
  chat : ChatService
  models : ModelsService
}

///|
pub fn OpenRouter::new(
  base_url? : String = BaseUrl,
  api_key~ : String,
) -> OpenRouter raise @uri.ParseError {
  let client = Client::new(base_url~, api_key~)
  OpenRouter::{
    client,
    chat: ChatService::new(client),
    models: ModelsService::new(client),
  }
}

///|
pub fn OpenRouter::close(self : OpenRouter) -> Unit {
  self.client.close()
}

///|
const PackageName = "@moonbitlang/maria/internal/openrouter"
