///|
pub struct OpenRouter {
  chat : ChatService
}

///|
pub fn OpenRouter::new(api_key~ : String) -> OpenRouter {
  let client = Client::new(api_key~)
  OpenRouter::{ chat: ChatService::new(client) }
}
///|
const PackageName = "@moonbitlang/maria/internal/openrouter"
